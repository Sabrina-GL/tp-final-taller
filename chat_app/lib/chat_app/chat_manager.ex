defmodule ChatApp.ChatManager do
  use GenServer
  alias ChatApp.{Accounts, ChatRoomSupervisor, ChatRoom, Notifications}

  # CLIENT API

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_or_create_private_chat(user1, user2) do
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
    if user1 == user2 do
      {:reply, {:error, :cannot_chat_with_self}, state}
    else
      chat_id_1 = "#{Enum.sort([user1, user2]) |> Enum.join(":")}"
      chat_id_2 = "#{Enum.sort([user2, user1]) |> Enum.join(":")}"
      participants = [user1, user2]

      with {:ok, _} <- Accounts.get_user(user1),
           {:ok, _} <- Accounts.get_user(user2) do
        case Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id_1) do
          [] ->
            case Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id_2) do
              [] ->
                {:ok, _pid} =
                  DynamicSupervisor.start_child(ChatRoomSupervisor, %{
                    id: ChatRoom,
                    start:
                      {ChatRoom, :start_link,
                       [
                         %{
                           chat_id: chat_id_1,
                           type: :private,
                           participants: participants,
                           messages: []
                         }
                       ]}
                  })

                Accounts.add_chatroom(user1, chat_id_1)
                Accounts.add_chatroom(user2, chat_id_1)

                # Notifico solo al usuario agregado
                Notifications.notify_new_chatroom(user2, chat_id_1)

                {:reply, {:ok, chat_id_1}, state}

              [{_pid, _}] ->
                {:reply, {:ok, chat_id_2}, state}
            end

          [{_pid, _}] ->
            {:reply, {:ok, chat_id_1}, state}
        end
      else
        {:error, reason} -> {:reply, {:error, reason}, state}
      end
    end
  end

  def handle_call({:search_messages, chat_id, keyword}, _from, state) do
    case Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id) do
      [] ->
        {:reply, {:error, :chat_not_found}, state}

      [{pid, _}] ->
        results = ChatRoom.search_messages(pid, keyword)
        {:reply, {:ok, results}, state}
    end
  end
end
