ExUnit.start()

config = ChatApp.Repo.config()

case Ecto.Adapters.Postgres.storage_up(config) do
	:ok -> :ok
	{:error, :already_up} -> :ok
	{:error, reason} -> raise "Failed to create test database: #{inspect(reason)}"
end

{:ok, _} = Application.ensure_all_started(:chat_app)

Code.require_file("support/data_case.ex", __DIR__)

# Ensure Repo is started
:timer.sleep(100)

# Run migrations for test environment
path = Application.app_dir(:chat_app, "priv/repo/migrations")
Ecto.Migrator.with_repo(ChatApp.Repo, fn repo -> Ecto.Migrator.run(repo, path, :up, all: true) end)

Ecto.Adapters.SQL.Sandbox.checkout(ChatApp.Repo)
Ecto.Adapters.SQL.Sandbox.mode(ChatApp.Repo, {:shared, self()})
