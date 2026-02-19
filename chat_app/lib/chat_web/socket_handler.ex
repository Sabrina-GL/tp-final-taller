defmodule ChatWeb.SocketHandler do
  @behaviour :cowboy_websocket
  alias ChatApp.{
    ActivitySupervisor,
    ActivityServer,
    Accounts,
    ChatManager,
    ChatRoomServer,
    Notifications
  }

  # Callback requerido por cowboy_websocket
  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    IO.puts("Cliente conectado: #{state.user}")
    Registry.register(ChatApp.UsersRegistry, state.user, self())
    ActivitySupervisor.start_activity_server(state.user)
    ActivityServer.user_online(state.user)

    notifications = Notifications.get_pending_notifications(state.user)

    if notifications != [] do
      send(self(), {:initial_notifications, notifications})
    end

    {:ok, state}
  end

  def websocket_handle({:text, msg}, state) do
    data = Jason.decode!(msg)

    reply =
      case data["action"] do
        "get_contacts" ->
          case Accounts.get_contacts(state.user) do
            {:ok, contacts} ->
              contacts_with_status =
                Enum.map(contacts, fn contact ->
                  online = ChatApp.ActivityServer.is_online?(contact)
                  %{username: contact, online: online}
                end)

              %{contacts: contacts_with_status}

            {:error, reason} ->
              %{error: reason}
          end

        "get_chatrooms" ->
          case ChatManager.get_user_chatrooms(state.user) do
            {:error, reason} -> %{error: reason}
            chatrooms -> %{chatrooms: chatrooms}
          end

        "get_messages" ->
          {:ok, messages} = ChatRoomServer.get_messages(data["chat_id"])
          %{messages: messages}

        "get_status" ->
          user = data["user"] || state.user
          online? = ActivityServer.is_online?(user)

          # last_seen returns {:ok, timestamp} or {:error, reason}
          last_seen_value =
            case ActivityServer.last_seen(user) do
              %DateTime{} = dt -> DateTime.to_unix(dt)
              ts when is_integer(ts) -> ts
              _ -> nil
            end

          %{user: user, online: online?, last_seen: last_seen_value}

        "add_contact" ->
          with :ok <- Accounts.add_contact(state.user, data["contact"]),
               {:ok, contacts} <- Accounts.get_contacts(state.user),
               {:ok, _chat_id} <-
                 ChatManager.create_private_chat(state.user, data["contact"]),
               chatrooms <- ChatManager.get_user_chatrooms(state.user) do
            contacts_with_status =
              Enum.map(contacts, fn contact ->
                online = ChatApp.ActivityServer.is_online?(contact)
                %{username: contact, online: online}
              end)

            %{
              status: :contact_added,
              contacts: contacts_with_status,
              chatrooms: chatrooms,
              chat_opened: true,
              chat_id: "#{Enum.sort([state.user, data["contact"]]) |> Enum.join(":")}"
            }
          else
            {:error, reason} -> %{error: reason}
          end

        "block_contact" ->
          case Accounts.block_contact(state.user, data["contact"]) do
            :ok -> %{status: :contact_blocked, contact: data["contact"]}
            {:error, reason} -> %{error: reason}
          end

        "create_group_chat" ->
          with {:ok, chat_id} <-
                 ChatManager.create_group_chat(
                   state.user,
                   data["group_name"],
                   data["participants"]
                 ) do
            %{
              status: :group_chat_created,
              chat_id: chat_id,
              group_name: data["group_name"]
            }
          else
            {:error, reason} -> %{error: reason}
          end

        "send_message" ->
          case ChatRoomServer.add_message(data["chat_id"], state.user, data["msg_content"]) do
            {:error, reason} ->
              %{status: :error, error: reason}

            message ->
              # Las notificaciones ya son manejadas por ChatRoomServer.add_message
              %{status: :ok, message: message}
          end

        "send_file" ->
          # Validate required fields
          with {:ok, file_content} <- validate_field(data, "file_content"),
               {:ok, file_name} <- validate_field(data, "file_name"),
               {:ok, file_type} <- validate_field(data, "file_type"),
               {:ok, chat_id} <- validate_field(data, "chat_id") do
            file_data = %{
              base64_content: file_content,
              filename: file_name,
              mime_type: file_type
            }

            case ChatRoomServer.add_message(chat_id, state.user, nil, file_data: file_data) do
              {:error, reason} ->
                %{status: :error, error: reason}

              message ->
                %{status: :ok, message: message, type: :file}
            end
          else
            {:error, field} -> %{status: :error, error: "Missing required field: #{field}"}
          end

        "search_messages" ->
          case ChatRoomServer.search_messages(data["chat_id"], data["query"]) do
            {:ok, messages} -> %{messages: messages}
            {:error, reason} -> %{status: :error, error: reason}
          end

        "delete_message" ->
          case ChatRoomServer.delete_message(data["chat_id"], state.user, data["message_id"]) do
            :ok -> %{status: :message_deleted, message_id: data["message_id"]}
            {:error, reason} -> %{status: :error, error: reason}
          end

        "delete_messages" ->
          case ChatRoomServer.delete_messages(
                 data["chat_id"],
                 state.user,
                 data["message_ids"] || []
               ) do
            {:ok, deleted_count} -> %{status: :messages_deleted, deleted_count: deleted_count}
            {:error, reason} -> %{status: :error, error: reason}
          end

        _ ->
          %{error: :unknown_action}
      end

    {:reply, {:text, Jason.encode!(reply)}, state}
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  def websocket_info({:new_chatroom, chat_id}, state) do
    reply = Jason.encode!(%{type: :new_chatroom, chat_id: chat_id})
    {:reply, {:text, reply}, state}
  end

  def websocket_info({:new_message, chat_id, message}, state) do
    reply = Jason.encode!(%{status: :new_message, chat_id: chat_id, message: message})
    {:reply, {:text, reply}, state}
  end

  def websocket_info({:added_as_contact, contact}, state) do
    reply = Jason.encode!(%{status: :added_as_contact, contact: contact})
    {:reply, {:text, reply}, state}
  end

  def websocket_info({:initial_notifications, notifications}, state) do
    {:reply,
     {:text, Jason.encode!(%{type: "initial_notifications", notifications: notifications})},
     state}
  end

  def websocket_info({:websocket_message, message}, state) do
    {:reply, {:text, message}, state}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  # Private helper function
  defp validate_field(data, field_name) do
    case Map.get(data, field_name) do
      nil -> {:error, field_name}
      "" -> {:error, field_name}
      value -> {:ok, value}
    end
  end

  def terminate(_reason, _request, state) do
    ChatApp.ActivityServer.user_offline(state.user)
    :ok
  end
end
