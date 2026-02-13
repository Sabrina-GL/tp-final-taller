defmodule ChatApp.ChatRoom do
  use GenServer

  # CLIENT API

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: via_tuple(state.chat_id))
  end

  def add_message(pid, from, text) do
    GenServer.cast(pid, {:add_message, from, text})
  end

  defp via_tuple(chat_id) do
    {:via, Registry, {ChatApp.ChatRoomsRegistry, chat_id}}
  end

  def search_messages(pid, keyword) do
    GenServer.call(pid, {:search_messages, keyword})
  end

  # SERVER

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:add_message, from, text}, state) do
    message = %{
      from: from,
      text: text,
      timestamp: DateTime.utc_now()
    }

    messages =
      [message | state.messages]
      |> Enum.take(10)

    new_state = %{state | messages: messages}
    {:noreply, new_state}
  end

  def handle_call({:search_messages, keyword}, _from, state) do
    results =
      state.messages
      |> Enum.filter(fn msg ->
        String.contains?(
          String.downcase(msg.text),
          String.downcase(keyword)
        )
      end)

    {:reply, results, state}
  end
end
