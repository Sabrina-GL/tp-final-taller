defmodule ChatApp.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:contact_id, references(:users, on_delete: :delete_all), null: false)
      add(:status, :string, default: "active", null: false)

      timestamps()
    end

    create(unique_index(:contacts, [:user_id, :contact_id]))
  end
end
