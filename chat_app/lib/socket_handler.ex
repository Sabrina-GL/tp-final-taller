defmodule SocketHandler do
  @behaviour :cowboy_websocket
  def init(request, _state) do
    {:cowboy_websocket, request, %{}}
  end

  def websocket_init(state) do
    IO.puts("Cliente conectado")
    {:ok, state}
  end

  def websocket_handle({:text, msg}, state) do
    IO.inspect(msg, label: "Mensaje recibido")
    {:reply, {:text, msg}, state}
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  def terminate(_reason, _request, _state) do
    :ok
  end
end
