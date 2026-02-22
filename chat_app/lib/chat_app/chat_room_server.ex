defmodule ChatApp.ChatRoomServer do
  @moduledoc """
  GenServer que maneja la logica de un chatroom individual.

  Cada instancia de ChatRoomServer representa una sala de chat específica, ya sea privada o grupal, y mantiene:
  - Lista de participantes
  - Historial de mensajes (limitado a los últimos 10)
  - Tipo de sala (privada o grupal)

  Funcionalidades principales:
  - Agregar mensajes al chatroom, validando que el remitente sea participante y no esté bloqueado por ningún otro participante
  - Eliminar mensajes (individual o en lote) con validación de permisos
  - Consultar el historial de mensajes
  - Buscar mensajes por palabra clave
  - Notificar a los participantes sobre nuevos mensajes o eliminaciones en tiempo real
  - Cargar el historial de mensajes desde la base de datos al iniciar el GenServer
  """
  use GenServer
  import Ecto.Query

  alias ChatApp.{Repo, Accounts, Notifications, FileManager, ChatRoomSupervisor}
  alias ChatApp.Schemas.{Message, Chatroom}

  # ======== Client API ==========
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

  def get_room_state(chat_id) do
    GenServer.call(via_tuple(chat_id), {:get_room_state})
  end

  def search_messages(chat_id, keyword) do
    GenServer.call(via_tuple(chat_id), {:search_messages, keyword})
  end

  # ========= GenServer Callbacks ==========

  def init(state) do
    # Load messages from database on startup
    messages = load_messages_from_db(state.chat_id)
    new_state = %{state | messages: messages}
    {:ok, new_state}
  end

  def handle_call({:add_message, from, text, opts}, _from, state) do
    with true <- Enum.member?(state.participants, from),
         {:ok, _} <- Accounts.get_user(from),
         false <- Accounts.blocked_with_any?(from, state.participants) do
      handle_add_message(from, text, opts, state)
    else
      false -> {:reply, {:error, :not_participant}, state}
      true -> {:reply, {:error, :contact_blocked}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:delete_message, requester, message_id}, _from, state) do
    with true <- Enum.member?(state.participants, requester),
         %Message{} = message <- Repo.get(Message, message_id),
         true <- message.chat_id == state.chat_id do
      # Delete physical file if present
      if message.file_path do
        FileManager.delete_file(message.file_path)
      end

      Repo.delete(message)

      new_messages = Enum.reject(state.messages, fn msg -> msg.id == message_id end)

      broadcast_message_deleted(
        state.participants,
        requester,
        state.chat_id,
        message_id
      )

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
          FileManager.delete_file(msg.file_path)
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

  # ========== Funciones Privadas ==========
  defp handle_add_message(from, text, opts, state) do
    timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    file_data = Keyword.get(opts, :file_data)

    case process_file_upload(file_data, text) do
      {:ok, {file_attrs, message_content}} ->
        message =
          %{
            from: from,
            msg_content: message_content,
            timestamp: timestamp
          }
          |> Map.merge(file_attrs)

        db_attrs =
          %{
            chat_id: state.chat_id,
            from_user: from,
            content: message_content,
            timestamp: timestamp
          }
          |> Map.merge(file_attrs)

        case Repo.insert(Message.changeset(%Message{}, db_attrs)) do
          {:ok, db_message} ->
            message_with_id = Map.put(message, :id, db_message.id)
            new_state = add_message_to_state(message_with_id, state)

            notify_participants_new_message(
              state.participants,
              from,
              state.chat_id,
              message_with_id
            )

            {:reply, message_with_id, new_state}

          {:error, _changeset} ->
            {:reply, {:error, :failed_to_save_message}, state}
        end

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp process_file_upload(file_data, text) do
    if file_data do
      case save_uploaded_file(file_data) do
        {:ok, %{path: path, size: size}} ->
          attrs = %{
            file_type: file_data.mime_type,
            file_name: file_data.filename,
            file_path: path,
            file_size: size
          }

          {:ok, {attrs, text || "[File: #{file_data.filename}]"}}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:ok, {%{}, text}}
    end
  end

  defp add_message_to_state(message, state) do
    messages =
      [message | state.messages]
      |> Enum.take(10)

    %{state | messages: messages}
  end

  defp notify_participants_new_message(participants, from, chat_id, message) do
    Enum.each(participants, fn participant ->
      if participant != from do
        Notifications.notify_new_message(
          participant,
          chat_id,
          message
        )
      end
    end)
  end

  defp broadcast_message_deleted(participants, requester, chat_id, message_id) do
    Enum.each(participants, fn participant ->
      if participant != requester do
        case Registry.lookup(ChatApp.UsersRegistry, participant) do
          [{pid, _}] ->
            send(pid, {:message_deleted, chat_id, message_id})

          [] ->
            :ok
        end
      end
    end)
  end

  defp ensure_room_started(chat_id) do
    case Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id) do
      [] ->
        case Repo.get_by(Chatroom, chat_id: chat_id) do
          nil ->
            {:error, :chat_not_found}

          chatroom ->
            ChatRoomSupervisor.start_chatroom(%{
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

  defp save_uploaded_file(%{base64_content: base64, filename: filename, mime_type: mime_type}) do
    FileManager.save_file(base64, filename, mime_type)
  end
end
