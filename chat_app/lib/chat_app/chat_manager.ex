defmodule ChatApp.ChatManager do
  # use GenServer
  import Ecto.Query
  alias ChatApp.Schemas.{Chatroom}
  alias ChatApp.{Repo, Accounts, ChatRoomSupervisor, Notifications}

  def init(state) do
    {:ok, state}
  end

  def create_private_chat(user1, user2) do
    with false <- user1 == user2,
         true <- Accounts.account_exists?(user1),
         true <- Accounts.account_exists?(user2) do
      chat_id = "#{Enum.sort([user1, user2]) |> Enum.join(":")}"
      participants = [user1, user2]

      case Repo.get_by(Chatroom, chat_id: chat_id) do
        nil ->
          {:ok, _chatroom} =
            %Chatroom{}
            |> Chatroom.create_private_changeset(user1, user2)
            |> Repo.insert()

          case ChatRoomSupervisor.start_chatroom(%{
                 chat_id: chat_id,
                 type: :private,
                 participants: participants,
                 messages: []
               }) do
            {:ok, _pid} -> :ok
            {:error, {:already_started, _pid}} -> :ok
          end

          # Notifico solo al usuario agregado
          Notifications.notify_new_chatroom(user2, chat_id)

          {:ok, chat_id}

        _ ->
          ensure_room_running(chat_id)
          {:ok, chat_id}
      end
    else
      true -> {:error, :cannot_chat_with_self}
      false -> {:error, :user_not_found}
    end
  end

  def create_group_chat(creator, group_name, participants) do
    chat_id = "group:" <> group_name
    all_participants = [creator | participants] |> Enum.uniq()

    with :ok <- validate_participants_exist(all_participants) do
      case Repo.get_by(Chatroom, chat_id: chat_id) do
        nil ->
          {:ok, _chatroom} =
            %Chatroom{}
            |> Chatroom.create_group_changeset(creator, group_name, participants)
            |> Repo.insert()

          case ChatRoomSupervisor.start_chatroom(%{
                 chat_id: chat_id,
                 group_name: group_name,
                 type: :group,
                 participants: all_participants,
                 messages: []
               }) do
            {:ok, _pid} -> :ok
            {:error, {:already_started, _pid}} -> :ok
          end

          Enum.each(all_participants, fn user ->
            # Accounts.add_chatroom(user, chat_id)
            # Solo notificar a los participantes que no son el creador
            if user != creator do
              Notifications.notify_new_chatroom(user, chat_id)
            end
          end)

          {:ok, chat_id}

        _ ->
          {:error, :group_name_taken}
      end
    end
  end

  defp validate_participants_exist(participants) do
    case Enum.all?(participants, &Accounts.account_exists?/1) do
      true -> :ok
      false -> {:error, :user_not_found}
    end
  end

  def get_user_chatrooms(user) do
    with true <- Accounts.account_exists?(user) do
      query =
        from(c in Chatroom,
          where: ^user in c.participants,
          select: c.chat_id
        )

      chat_ids = Repo.all(query)

      Enum.each(chat_ids, &ensure_room_running/1)

      chat_ids
    else
      false -> {:error, :user_not_found}
    end
  end

  defp ensure_room_running(chat_id) do
    case Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id) do
      [] ->
        chatroom = Repo.get_by(Chatroom, chat_id: chat_id)

        ChatRoomSupervisor.start_chatroom(%{
          chat_id: chatroom.chat_id,
          type: String.to_atom(chatroom.type),
          group_name: chatroom.name,
          participants: chatroom.participants
        })

      _ ->
        :ok
    end
  end

  # def handle_call({:search_messages, chat_id, keyword}, _from, state) do
  #   case Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id) do
  #     [] ->
  #       {:reply, {:error, :chat_not_found}, state}

  #     [{_pid, _}] ->
  #       results = ChatRoom.search_messages(chat_id, keyword)
  #       {:reply, {:ok, results}, state}
  #   end
  # end

  # CLIENT API

  # def start_link(_) do
  #   GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  # end

  # def get_or_create_private_chat(user1, user2) do
  #   GenServer.call(__MODULE__, {:get_or_create_private_chat, user1, user2})
  # end

  # def get_chat(chat_id) do
  #   GenServer.call(__MODULE__, {:get_chat, chat_id})
  # end

  # def create_group_chat(creator, group_name, participants) do
  #   GenServer.call(__MODULE__, {:create_group_chat, creator, group_name, participants})
  # end

  # def search_messages(chat_id, keyword) do
  #   GenServer.call(__MODULE__, {:search_messages, chat_id, keyword})
  # end

  # SERVER

  #   def init(state) do
  #     {:ok, state}
  #   end

  #   def handle_call({:get_or_create_private_chat, user1, user2}, _from, state) do
  #     if user1 == user2 do
  #       {:reply, {:error, :cannot_chat_with_self}, state}
  #     else
  #       chat_id_1 = "#{Enum.sort([user1, user2]) |> Enum.join(":")}"
  #       participants = [user1, user2]

  #       with {:ok, _} <- Accounts.get_user(user1),
  #            {:ok, _} <- Accounts.get_user(user2) do
  #         case Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id_1) do
  #           [] ->
  #             {:ok, _pid} =
  #               DynamicSupervisor.start_child(ChatRoomSupervisor, %{
  #                 id: ChatRoom,
  #                 start:
  #                   {ChatRoom, :start_link,
  #                    [
  #                      %{
  #                        chat_id: chat_id_1,
  #                        type: :private,
  #                        participants: participants,
  #                        messages: []
  #                      }
  #                    ]}
  #               })

  #             Accounts.add_chatroom(user1, chat_id_1)
  #             Accounts.add_chatroom(user2, chat_id_1)

  #             # Notifico solo al usuario agregado
  #             Notifications.notify_new_chatroom(user2, chat_id_1)

  #             {:reply, {:ok, chat_id_1}, state}

  #           [{_pid, _}] ->
  #             {:reply, {:ok, chat_id_1}, state}
  #         end
  #       else
  #         {:error, reason} -> {:reply, {:error, reason}, state}
  #       end
  #     end
  #   end

  #   def handle_call({:create_group_chat, creator, name, participants}, _from, state) do
  #     chat_id = "group:" <> name

  #     all_participants =
  #       [creator | participants]
  #       |> Enum.uniq()

  #     {:ok, _pid} =
  #       DynamicSupervisor.start_child(ChatRoomSupervisor, %{
  #         id: ChatRoom,
  #         start:
  #           {ChatRoom, :start_link,
  #            [
  #              %{
  #                chat_id: chat_id,
  #                group_name: name,
  #                type: :group,
  #                participants: all_participants,
  #                messages: []
  #              }
  #            ]}
  #       })

  #     Enum.each(all_participants, fn user ->
  #       Accounts.add_chatroom(user, chat_id)
  #       # Solo notificar a los participantes que no son el creador
  #       if user != creator do
  #         Notifications.notify_new_chatroom(user, chat_id)
  #       end
  #     end)

  #     {:reply, {:ok, chat_id}, state}
  #   end

  #   def handle_call({:search_messages, chat_id, keyword}, _from, state) do
  #     case Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id) do
  #       [] ->
  #         {:reply, {:error, :chat_not_found}, state}

  #       [{_pid, _}] ->
  #         results = ChatRoom.search_messages(chat_id, keyword)
  #         {:reply, {:ok, results}, state}
  #     end
  #   end
end
