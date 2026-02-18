defmodule ChatApp.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :chat_id, :string, null: false
      add :from_user, :string, null: false
      add :content, :text, null: false
      add :timestamp, :naive_datetime, null: false
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:messages, [:chat_id])
    create index(:messages, [:user_id])
    create index(:messages, [:timestamp])
  end
end
