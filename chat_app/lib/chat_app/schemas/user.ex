defmodule ChatApp.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias ChatApp.Schemas.{Message, Contact}

  schema "users" do
    field(:username, :string)
    field(:password_hash, :string)
    field(:last_seen, :naive_datetime)

    has_many(:messages, Message, foreign_key: :user_id)
    has_many(:contacts, Contact, foreign_key: :user_id)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password_hash, :last_seen])
    |> validate_required([:username, :password_hash])
    |> unique_constraint(:username)
  end

  @doc false
  def create_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> validate_length(:username, min: 3, max: 20)
  end

  @doc false
  def update_last_seen(user, datetime \\ NaiveDateTime.utc_now()) do
    change(user, last_seen: datetime)
  end
end
