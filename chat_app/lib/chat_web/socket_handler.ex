defmodule ChatWeb.SocketHandler do
  @behaviour :cowboy_websocket

  # Callback requerido por cowboy_websocket
  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    IO.puts("Cliente conectado: #{state.user}")
    Registry.register(ChatApp.UsersRegistry, state.user, self())
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

        "send_message" ->
          message = ChatApp.ChatRoom.add_message(data["chat_id"], state.user, data["msg_content"])

          %{status: :new_message, chat_id: data["chat_id"], msg_content: message}

        _ ->
          %{error: :unknown_action}
      end

    {:reply, {:text, Jason.encode!(reply)}, state}
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  def websocket_info({:new_chatroom, chat_id}, state) do
    payload = Jason.encode!(%{type: :new_chatroom, chat_id: chat_id})
    {:reply, {:text, payload}, state}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  def terminate(_reason, _request, _state) do
    :ok
  end

  defp open_chat_room(user1, user2) do
    chat_id = "#{Enum.sort([user1, user2]) |> Enum.join(":")}"

    with {:ok, _chat_pid} <- ChatApp.ChatManager.get_or_create_private_chat(user1, user2) do
      %{status: :chat_opened, chat_id: chat_id, type: :private}
    else
      {:error, reason} -> %{error: reason}
    end
  end
end
