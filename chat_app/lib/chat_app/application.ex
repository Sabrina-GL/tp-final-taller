defmodule ChatApp.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Obtener puerto de configuración, con fallback a 4000
    port = Application.get_env(:chat_app, :websocket_port, 4000)

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
        options: [port: port]
      )
    ]

    opts = [strategy: :one_for_one, name: ChatApp.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        case run_startup_migrations() do
          :ok ->
            IO.puts("\n" <> String.duplicate("=", 50))
            IO.puts("💬 Chat application started on port #{port}")
            IO.puts("   WebSocket: ws://localhost:#{port}/ws?user=username")
            IO.puts("   HTTP: http://localhost:#{port}")
            IO.puts(String.duplicate("=", 50) <> "\n")
            {:ok, pid}

          {:error, reason} ->
            Logger.error("Startup migrations failed: #{inspect(reason)}")
            Supervisor.stop(pid)
            {:error, reason}
        end

      error ->
        error
    end
  end

  defp run_startup_migrations do
    if Application.get_env(:chat_app, :auto_migrate_on_start, true) do
      migrations_path = Application.app_dir(:chat_app, "priv/repo/migrations")

      case Ecto.Migrator.with_repo(ChatApp.Repo, fn repo ->
             Ecto.Migrator.run(repo, migrations_path, :up, all: true)
           end) do
        {:ok, _migrated, _apps} ->
          :ok

        other ->
          {:error, other}
      end
    else
      :ok
    end
  rescue
    exception ->
      {:error, exception}
  end
end
