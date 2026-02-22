ExUnit.start()

# Forzar recreación de la base de datos de test
config = ChatApp.Repo.config()

# Eliminar DB si existe
case Ecto.Adapters.Postgres.storage_down(config) do
  :ok -> IO.puts("Bdd de test eliminada")
  {:error, :already_down} -> :ok
  {:error, reason} -> IO.puts("No se pudo eliminar bdd: #{inspect(reason)}")
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
