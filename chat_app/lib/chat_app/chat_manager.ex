defmodule ChatApp.ChatManager do
  use GenServer

  # CLIENT API

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_or_create_private_chat(user1, user2) do
    participants = [user1, user2]
    chat_id = "private:#{Enum.sort(participants) |> Enum.join(":")}"
    GenServer.call(__MODULE__, {:get_or_create_private_chat, user1, user2})
  end

  def get_chat(chat_id) do
    GenServer.call(__MODULE__, {:get_chat, chat_id})
  end

  def search_messages(chat_id, keyword) do
    GenServer.call(__MODULE__, {:search_messages, chat_id, keyword})
  end

  # SERVER

  def init(state) do
    {:ok, state}
  end

  def handle_call({:get_or_create_private_chat, user1, user2}, _from, state) do
    chat_id_1 = "#{Enum.sort([user1, user2]) |> Enum.join(":")}"
    chat_id_2 = "#{Enum.sort([user2, user1]) |> Enum.join(":")}"
    participants = [user1, user2]

    case Map.get(state, chat_id_1) do
      nil ->
        case Map.get(state, chat_id_2) do
          nil ->
            {:ok, pid} =
              DynamicSupervisor.start_child(ChatApp.ChatRoomSupervisor, %{
                id: ChatApp.ChatRoom,
                start:
                  {ChatApp.ChatRoom, :start_link,
                   [
                     %{
                       chat_id: chat_id_1,
                       type: :private,
                       participants: participants,
                       messages: []
                     }
                   ]}
              })

            # ChatApp.ChatRoom.start_link(%{
            #   chat_id: chat_id_1,
            #   type: :private,
            #   participants: participants,
            #   messages: []
            # })

            new_state = Map.put(state, chat_id_1, pid)
            {:reply, {:ok, chat_id_1}, new_state}

          pid ->
            {:reply, {:ok, chat_id_2}, state}
        end

      pid ->
        {:reply, {:ok, chat_id_1}, state}
    end
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
