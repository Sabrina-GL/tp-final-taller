defmodule ChatApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChatApp.Repo,
      {Registry, keys: :unique, name: ChatApp.UsersRegistry},
      {Registry, keys: :unique, name: ChatApp.ChatRoomsRegistry},
      {Registry, keys: :unique, name: ChatApp.ActivityRegistry},
      ChatApp.ActivitySupervisor,
      ChatApp.ChatRoomSupervisor,
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: ChatWeb.Router,
        options: [port: 4000]
      )
    ]

    opts = [strategy: :one_for_one, name: ChatApp.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        IO.puts("\n" <> String.duplicate("=", 50))
        IO.puts("💬 Chat application started on port 4000")
        IO.puts("   WebSocket: ws://localhost:4000/ws?user=username")
        IO.puts("   HTTP: http://localhost:4000")
        IO.puts(String.duplicate("=", 50) <> "\n")
        {:ok, pid}

      error ->
        error
    end
  end
end
