defmodule ChatApp.ChatRoomServer do
  use GenServer
  import Ecto.Query

  alias ChatApp.{Repo, Accounts}
  alias ChatApp.Schemas.Message

  # CLIENT API

  def start_link(%{chat_id: chat_id} = state) do
    GenServer.start_link(__MODULE__, state, name: via_tuple(chat_id))
  end

  defp via_tuple(chat_id) do
    {:via, Registry, {ChatApp.ChatRoomsRegistry, chat_id}}
  end

  def add_message(chat_id, from, text, opts \\ []) do
    GenServer.call(via_tuple(chat_id), {:add_message, from, text, opts})
  end

  def delete_message(chat_id, requester, message_id) do
    GenServer.call(via_tuple(chat_id), {:delete_message, requester, message_id})
  end

  def delete_messages(chat_id, requester, message_ids) do
    GenServer.call(via_tuple(chat_id), {:delete_messages, requester, message_ids})
  end

  def get_messages(chat_id) do
    ensure_room_started(chat_id)
    GenServer.call(via_tuple(chat_id), {:get_messages})
  end

  defp ensure_room_started(chat_id) do
    case Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id) do
      [] ->
        case ChatApp.Repo.get_by(ChatApp.Schemas.Chatroom, chat_id: chat_id) do
          nil ->
            {:error, :chat_not_found}

          chatroom ->
            ChatApp.ChatRoomSupervisor.start_chatroom(%{
              chat_id: chatroom.chat_id,
              type: String.to_atom(chatroom.type),
              group_name: chatroom.name,
              participants: chatroom.participants,
              messages: load_messages_from_db(chat_id)
            })
        end

      _ ->
        :ok
    end
  end

  def get_room_state(chat_id) do
    GenServer.call(via_tuple(chat_id), {:get_room_state})
  end

  def search_messages(chat_id, keyword) do
    GenServer.call(via_tuple(chat_id), {:search_messages, keyword})
  end

  # SERVER

  def init(state) do
    # Load messages from database on startup
    messages = load_messages_from_db(state.chat_id)
    new_state = %{state | messages: messages}
    {:ok, new_state}
  end

  defp load_messages_from_db(chat_id) do
    Message
    |> where([m], m.chat_id == ^chat_id)
    |> order_by([m], desc: m.timestamp)
    |> limit(10)
    |> Repo.all()
    |> Enum.map(fn msg ->
      base_msg = %{
        id: msg.id,
        from: msg.from_user,
        msg_content: msg.content,
        timestamp: msg.timestamp
      }

      # Add file fields if present
      if msg.file_path do
        Map.merge(base_msg, %{
          file_type: msg.file_type,
          file_name: msg.file_name,
          file_path: msg.file_path,
          file_size: msg.file_size
        })
      else
        base_msg
      end
    end)
    |> Enum.reverse()
  end

  def handle_call({:add_message, from, text, opts}, _from, state) do
    with true <- Enum.member?(state.participants, from),
         {:ok, _} <- Accounts.get_user(from),
         false <- Accounts.blocked_with_any?(from, state.participants) do
      timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      # Handle file upload if present
      file_data = Keyword.get(opts, :file_data)

      {file_attrs, message_content} =
        if file_data do
          case save_uploaded_file(file_data) do
            {:ok, %{path: path, size: size}} ->
              attrs = %{
                file_type: file_data.mime_type,
                file_name: file_data.filename,
                file_path: path,
                file_size: size
              }
              {attrs, text || "[File: #{file_data.filename}]"}
            {:error, reason} ->
              # If file upload fails, return error
              {:reply, {:error, reason}, state}
              |> then(fn result -> throw(result) end)
          end
        else
          {%{}, text}
        end

      message = %{
        from: from,
        msg_content: message_content,
        timestamp: timestamp
      }
      |> Map.merge(file_attrs)

      # Persist message to database
      db_attrs = %{
        chat_id: state.chat_id,
        from_user: from,
        content: message_content,
        timestamp: timestamp
      }
      |> Map.merge(file_attrs)

      db_changeset = Message.changeset(%Message{}, db_attrs)

      case Repo.insert(db_changeset) do
        {:ok, db_message} ->
          message_with_id = Map.put(message, :id, db_message.id)

          messages =
            [message_with_id | state.messages]
            |> Enum.take(10)

          new_state = %{state | messages: messages}

          # Notificar a todos los participantes excepto al remitente
          Enum.each(state.participants, fn participant ->
            if participant != from do
              ChatApp.Notifications.notify_new_message(participant, state.chat_id, message_with_id)
            end
          end)

          {:reply, message_with_id, new_state}

        {:error, _changeset} ->
          {:reply, {:error, :failed_to_save_message}, state}
      end
    else
      false -> {:reply, {:error, :not_participant}, state}
      true -> {:reply, {:error, :contact_blocked}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  catch
    result -> result
  end

  defp save_uploaded_file(%{base64_content: base64, filename: filename, mime_type: mime_type}) do
    ChatApp.FileManager.save_file(base64, filename, mime_type)
  end

  def handle_call({:delete_message, requester, message_id}, _from, state) do
    with true <- Enum.member?(state.participants, requester),
         %Message{} = message <- Repo.get(Message, message_id),
         true <- message.chat_id == state.chat_id do
      # Delete physical file if present
      if message.file_path do
        ChatApp.FileManager.delete_file(message.file_path)
      end

      Repo.delete(message)

      new_messages = Enum.reject(state.messages, fn msg -> msg.id == message_id end)
      {:reply, :ok, %{state | messages: new_messages}}
    else
      false -> {:reply, {:error, :not_participant}, state}
      nil -> {:reply, {:error, :message_not_found}, state}
      _ -> {:reply, {:error, :message_not_found}, state}
    end
  end

  def handle_call({:delete_messages, requester, message_ids}, _from, state) do
    with true <- Enum.member?(state.participants, requester),
         true <- is_list(message_ids) do
      # Delete physical files if present
      messages_to_delete =
        Message
        |> where([m], m.chat_id == ^state.chat_id and m.id in ^message_ids)
        |> Repo.all()

      Enum.each(messages_to_delete, fn msg ->
        if msg.file_path do
          ChatApp.FileManager.delete_file(msg.file_path)
        end
      end)

      {deleted_count, _} =
        Message
        |> where([m], m.chat_id == ^state.chat_id and m.id in ^message_ids)
        |> Repo.delete_all()

      new_messages = Enum.reject(state.messages, fn msg -> msg.id in message_ids end)

      {:reply, {:ok, deleted_count}, %{state | messages: new_messages}}
    else
      false -> {:reply, {:error, :not_participant}, state}
      _ -> {:reply, {:error, :invalid_message_ids}, state}
    end
  end

  def handle_call({:get_messages}, _from, state) do
    {:reply, {:ok, state.messages}, state}
  end

  def handle_call({:get_room_state}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call({:search_messages, keyword}, _from, state) do
    results =
      state.messages
      |> Enum.filter(fn msg ->
        String.contains?(
          String.downcase(msg.msg_content),
          String.downcase(keyword)
        )
      end)

    {:reply, results, state}
  end
end
