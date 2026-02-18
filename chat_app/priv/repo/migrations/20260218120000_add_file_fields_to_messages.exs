defmodule ChatApp.Repo.Migrations.AddFileFieldsToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :file_type, :string
      add :file_name, :string
      add :file_path, :string
      add :file_size, :integer
    end

    # Make content nullable since messages can now be files without text
    execute "ALTER TABLE messages ALTER COLUMN content DROP NOT NULL",
            "ALTER TABLE messages ALTER COLUMN content SET NOT NULL"

    # Add index for file_path to speed up lookups
    create index(:messages, [:file_path])
  end
end
