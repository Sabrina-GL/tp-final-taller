defmodule SocketHandler do
  @behaviour :cowboy_websocket
  def init(request, _state) do
    %{user: user} = :cowboy_req.match_qs([{:user, [], nil}], request)
    {:cowboy_websocket, request, %{user: user}}
  end

  def websocket_init(state) do
    IO.puts("Cliente conectado")
    {:ok, state}
  end

  def websocket_handle({:text, msg}, state) do
    data = Jason.decode!(msg)

    reply =
      case data["action"] do
        # "register" -> ChatApp.Accounts.register_user(data["username"], data["password"])
        # "login" -> ChatApp.Accounts.authenticate_user(data["username"], data["password"])
        # _ -> {:error, :unknown_action}
        "ping" -> %{ok: true}
        _ -> %{error: :unknown_action}
      end

    {:reply, {:text, Jason.encode!(reply)}, state}
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  def terminate(_reason, _request, _state) do
    :ok
  end
end
