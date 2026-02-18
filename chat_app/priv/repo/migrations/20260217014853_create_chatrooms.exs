defmodule ChatApp.Repo.Migrations.CreateChatrooms do
  use Ecto.Migration

  def change do
    create table(:chatrooms) do
      add(:chat_id, :string, null: false)
      add(:name, :string)
      add(:type, :string, default: "private", null: false)
      add(:participants, {:array, :string}, default: [], null: false)

      timestamps()
    end

    create(unique_index(:chatrooms, [:chat_id]))
    create(index(:chatrooms, [:type]))
  end
end
