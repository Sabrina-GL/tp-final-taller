defmodule ChatApp.Schemas.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :chat_id, :string
    field :from_user, :string
    field :content, :string
    field :timestamp, :naive_datetime

    belongs_to :user, ChatApp.Schemas.User, foreign_key: :user_id, type: :id

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:chat_id, :from_user, :content, :timestamp, :user_id])
    |> validate_required([:chat_id, :from_user, :content, :timestamp])
    |> validate_length(:content, min: 1, max: 1024)
  end

  @doc false
  def create_changeset(message, attrs) do
    message
    |> changeset(attrs)
    |> put_change(:timestamp, attrs[:timestamp] || NaiveDateTime.utc_now())
  end
end
