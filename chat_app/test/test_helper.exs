ExUnit.start()

{:ok, _} = Application.ensure_all_started(:chat_app)

# Ensure Repo is started
:timer.sleep(100)

# Run migrations for test environment
Ecto.Migrator.run(ChatApp.Repo, :up, all: true)
