defmodule ChatApp.ChatRoom do
  use GenServer
  import Ecto.Query

  alias ChatApp.Repo
  alias ChatApp.Schemas.Message

  # CLIENT API

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: via_tuple(state.chat_id))
  end

  defp via_tuple(chat_id) do
    {:via, Registry, {ChatApp.ChatRoomsRegistry, chat_id}}
  end

  def add_message(chat_id, from, text) do
    GenServer.call(via_tuple(chat_id), {:add_message, from, text})
  end

  def get_messages(chat_id) do
    GenServer.call(via_tuple(chat_id), {:get_messages})
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
      %{
        from: msg.from_user,
        msg_content: msg.content,
        timestamp: msg.timestamp
      }
    end)
    |> Enum.reverse()
  end

  def handle_call({:add_message, from, text}, _from, state) do
    with true <- Enum.member?(state.participants, from),
         {:ok, _} <- ChatApp.Accounts.get_user(from) do
      timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      message = %{
        from: from,
        msg_content: text,
        timestamp: timestamp
      }

      # Persist message to database
      db_changeset =
        Message.changeset(%Message{}, %{
          chat_id: state.chat_id,
          from_user: from,
          content: text,
          timestamp: timestamp
        })

      case Repo.insert(db_changeset) do
        {:ok, _db_message} ->
          messages =
            [message | state.messages]
            |> Enum.take(10)

          new_state = %{state | messages: messages}

          # Notificar a todos los participantes excepto al remitente
          Enum.each(state.participants, fn participant ->
            if participant != from do
              ChatApp.Notifications.notify_new_message(participant, state.chat_id, message)
            end
          end)

          {:reply, message, new_state}

        {:error, _changeset} ->
          {:reply, {:error, :failed_to_save_message}, state}
      end
    else
      false -> {:reply, {:error, :not_participant}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
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
