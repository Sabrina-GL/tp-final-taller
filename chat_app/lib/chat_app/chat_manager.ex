defmodule ChatApp.ChatManager do
  # use GenServer
  import Ecto.Query
  alias ChatApp.Schemas.{Chatroom}
  alias ChatApp.{Repo, Accounts, ChatRoomSupervisor, Notifications}

  def init(state) do
    {:ok, state}
  end

  def create_private_chat(user1, user2) do
    cond do
      user1 == user2 ->
        {:error, :cannot_chat_with_self}

      not Accounts.account_exists?(user1) or not Accounts.account_exists?(user2) ->
        {:error, :user_not_found}

      Accounts.interaction_blocked?(user1, user2) ->
        {:error, :contact_blocked}

      true ->
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
    end
  end

  def create_group_chat(creator, group_name, participants) do
    chat_id = "group:" <> group_name
    all_participants = [creator | participants] |> Enum.uniq()

    with :ok <- validate_participants_exist(all_participants),
         false <- Accounts.has_blocked_pair?(all_participants) do
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
    else
      true -> {:error, :contact_blocked}
      {:error, reason} -> {:error, reason}
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
end
