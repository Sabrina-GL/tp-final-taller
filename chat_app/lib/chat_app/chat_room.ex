defmodule ChatApp.ChatRoom do
  use GenServer

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
    {:ok, state}
  end

  def handle_call({:add_message, from, text}, _from, state) do
    with true <- Enum.member?(state.participants, from),
         {:ok, _} <- ChatApp.Accounts.get_user(from) do
      message = %{
        from: from,
        msg_content: text,
        timestamp: DateTime.utc_now()
      }

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
