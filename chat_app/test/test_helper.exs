ExUnit.start()

# Forzar recreación de la base de datos de test
config = ChatApp.Repo.config()

terminate_test_db_connections = fn repo_config ->
  maintenance_db = repo_config[:maintenance_database] || "postgres"

  conn_opts = [
    hostname: repo_config[:hostname],
    port: repo_config[:port],
    username: repo_config[:username],
    password: repo_config[:password],
    database: maintenance_db
  ]

  case Postgrex.start_link(conn_opts) do
    {:ok, pid} ->
      _ =
        Postgrex.query(
          pid,
          """
          SELECT pg_terminate_backend(pid)
          FROM pg_stat_activity
          WHERE datname = $1
            AND pid <> pg_backend_pid()
          """,
          [repo_config[:database]]
        )

      GenServer.stop(pid)
      :ok

    {:error, _reason} ->
      :ok
  end
end

terminate_test_db_connections.(config)

# Eliminar DB si existe
case Ecto.Adapters.Postgres.storage_down(config) do
  :ok -> IO.puts("Bdd de test eliminada")
  {:error, :already_down} -> :ok

  {:error, reason} ->
    reason_text = inspect(reason)

    if String.contains?(reason_text, "object_in_use") do
      terminate_test_db_connections.(config)

      case Ecto.Adapters.Postgres.storage_down(config) do
        :ok -> IO.puts("Bdd de test eliminada (reintento)")
        {:error, :already_down} -> :ok
        {:error, retry_reason} -> IO.puts("No se pudo eliminar bdd: #{inspect(retry_reason)}")
      end
    else
      IO.puts("No se pudo eliminar bdd: #{reason_text}")
    end
end

# Crear DB nueva
case Ecto.Adapters.Postgres.storage_up(config) do
  :ok -> IO.puts("Bdd de test creada")
  {:error, :already_up} -> IO.puts("La bdd de test ya existe")
  {:error, reason} -> raise "Fallo al crear bdd: #{inspect(reason)}"
end

{:ok, _} = Application.ensure_all_started(:chat_app)

Code.require_file("support/data_case.ex", __DIR__)

# Ejecutar migraciones
path = Application.app_dir(:chat_app, "priv/repo/migrations")

Ecto.Migrator.with_repo(ChatApp.Repo, fn repo ->
  Ecto.Migrator.run(repo, path, :up, all: true)
end)

Ecto.Adapters.SQL.Sandbox.mode(ChatApp.Repo, :manual)
