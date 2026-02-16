defmodule ChatWeb.SocketHandler do
  @behaviour :cowboy_websocket

  # Callback requerido por cowboy_websocket
  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    IO.puts("Cliente conectado: #{state.user}")
    Registry.register(ChatApp.UsersRegistry, state.user, self())
    ChatApp.ActivityTracker.user_online(state.user)

    pending = ChatApp.ActivityTracker.consume_pending(state.user)
    Enum.each(pending, fn notification ->
      send(self(), notification)
    end)
    {:ok, state}
  end

  def websocket_handle({:text, msg}, state) do
    data = Jason.decode!(msg)

    reply =
      case data["action"] do
        # "register" ->
        #   ChatApp.Accounts.register_user(data["username"], data["password"])

        # "login" ->
        #   ChatApp.Accounts.authenticate_user(data["username"], data["password"])

        "get_contacts" ->
          case ChatApp.Accounts.get_contacts(state.user) do
            {:ok, contacts} -> %{contacts: contacts}
            {:error, reason} -> %{error: reason}
          end

        "get_chatrooms" ->
          case ChatApp.Accounts.get_chatrooms(state.user) do
            {:ok, chatrooms} -> %{chatrooms: chatrooms}
            {:error, reason} -> %{error: reason}
          end

        "get_messages" ->
          {:ok, messages} = ChatApp.ChatRoom.get_messages(data["chat_id"])
          %{messages: messages}

        "get_status" ->
          user = data["user"] || state.user
          online? = ChatApp.ActivityTracker.is_online?(user)

          # last_seen returns {:ok, timestamp} or {:error, reason}
          last_seen_value = case ChatApp.ActivityTracker.last_seen(user) do
            {:ok, %DateTime{} = dt} -> DateTime.to_unix(dt)
            {:ok, ts} when is_integer(ts) -> ts
            {:error, _} -> nil
            _ -> nil
          end

          %{user: user, online: online?, last_seen: last_seen_value}

        "add_contact" ->
          with :ok <- ChatApp.Accounts.add_contact(state.user, data["contact"]),
               {:ok, contacts} <- ChatApp.Accounts.get_contacts(state.user),
               {:ok, _chat_id} <-
                 ChatApp.ChatManager.get_or_create_private_chat(state.user, data["contact"]),
               #  :ok <- ChatApp.Accounts.add_chatroom(state.user, chat_id),
               #  :ok <-
               #    ChatApp.Accounts.add_chatroom(data["contact"], chat_id),
               {:ok, chatrooms} <- ChatApp.Accounts.get_chatrooms(state.user) do
            %{
              status: :contact_added,
              contacts: contacts,
              chatrooms: chatrooms,
              chat_opened: true,
              chat_id: "#{Enum.sort([state.user, data["contact"]]) |> Enum.join(":")}"
            }
          else
            {:error, reason} -> %{error: reason}
          end

        "create_group_chat" ->
          with {:ok, chat_id} <-
                 ChatApp.ChatManager.create_group_chat(
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
          case ChatApp.ChatRoom.add_message(data["chat_id"], state.user, data["msg_content"]) do
            {:error, reason} ->
              %{status: :error, error: reason}

            message ->
              # Las notificaciones ya son manejadas por ChatRoom.add_message
              %{status: :ok, message: message}
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

  def websocket_info(_info, state) do
    {:ok, state}
  end

  def terminate(_reason, _request, state) do
    ChatApp.ActivityTracker.user_offline(state.user)
    :ok
  end
end
