defmodule ChatWeb.SocketHandler do
  @behaviour :cowboy_websocket

  # def init(request, _state) do
  #   qs = :cowboy_req.parse_qs(request)

  #   user =
  #     case List.keyfind(qs, "user", 0) do
  #       {"user", username} when is_binary(username) and username != "" ->
  #         username

  #       _ ->
  #         nil
  #     end

  #   if user do
  #     IO.puts("WebSocket iniciando para usuario: #{user}")
  #     {:cowboy_websocket, request, %{user: user}}
  #   else
  #     # No hay usuario, rechazo conexión
  #     IO.puts("WebSocket rechazado: sin parámetro 'user'")
  #     {:shutdown, request}
  #   end
  # end

  def websocket_init(state) do
    IO.puts("Cliente conectado: #{state.user}")
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

        "add_contact" ->
          case ChatApp.Accounts.add_contact(state.user, data["contact"]) do
            :ok ->
              # %{status: :contact_added}
              {:ok, contacts} = ChatApp.Accounts.get_contacts(state.user)
              %{contacts: contacts}

            {:error, reason} ->
              %{error: reason}
          end

        _ ->
          %{error: :unknown_action}
      end

    {:reply, {:text, Jason.encode!(reply)}, state}
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  def terminate(_reason, _request, _state) do
    :ok
  end
end
