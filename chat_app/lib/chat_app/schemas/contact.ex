defmodule ChatApp.Schemas.Contact do
  use Ecto.Schema
  import Ecto.Changeset
  alias ChatApp.Schemas.User

  schema "contacts" do
    belongs_to(:user, User, foreign_key: :user_id, type: :id)
    belongs_to(:contact, User, foreign_key: :contact_id, type: :id)
    # active / blocked
    field(:status, :string, default: "active")
    timestamps()
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:user_id, :contact_id, :status])
    |> validate_required([:user_id, :contact_id])
    |> validate_inclusion(:status, ["active", "blocked"])
    |> unique_constraint([:user_id, :contact_id])
  end
end
