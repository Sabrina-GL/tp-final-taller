defmodule ChatApp.ChatManager do
  use GenServer

  # CLIENT API

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def create_chat(chat_id, participants) do
    GenServer.call(__MODULE__, {:create_chat, chat_id, participants})
  end

  def search_messages(chat_id, keyword) do
    GenServer.call(__MODULE__, {:search_messages, chat_id, keyword})
  end

  # SERVER

  def init(state) do
    {:ok, state}
  end

  def handle_call({:create_chat, chat_id, participants}, _from, state) do
    {:ok, pid} =
      ChatApp.ChatRoom.start_link(%{
        id: chat_id,
        participants: participants,
        messages: []
      })

    new_state = Map.put(state, chat_id, pid)
    {:reply, {:ok, pid}, new_state}
  end

  def handle_call({:search_messages, chat_id, keyword}, _from, state) do
    case Map.get(state, chat_id) do
      nil ->
        {:reply, {:error, :chat_not_found}, state}

      pid ->
        results = ChatApp.ChatRoom.search_messages(pid, keyword)
        {:reply, {:ok, results}, state}
    end
  end
end
