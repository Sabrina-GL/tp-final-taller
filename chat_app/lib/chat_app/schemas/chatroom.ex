defmodule ChatApp.Schemas.Chatroom do
  use Ecto.Schema
  import Ecto.Changeset
  alias ChatApp.Schemas.{Message}

  schema "chatrooms" do
    field(:chat_id, :string)
    field(:name, :string)
    field(:type, :string, default: "private")
    field(:participants, {:array, :string}, default: [])

    has_many(:messages, Message, foreign_key: :chat_id, references: :chat_id)

    timestamps()
  end

  @doc false
  def changeset(chatroom, attrs) do
    chatroom
    |> cast(attrs, [:chat_id, :name, :type, :participants])
    |> validate_required([:chat_id, :type, :participants])
    |> validate_length(:participants, min: 2)
    |> validate_inclusion(:type, ["private", "group"])
    |> unique_constraint(:chat_id)
  end

  def create_private_changeset(chatroom, user1, user2) do
    chat_id = "#{Enum.sort([user1, user2]) |> Enum.join(":")}"

    chatroom
    |> changeset(%{
      chat_id: chat_id,
      type: "private",
      participants: [user1, user2]
    })
  end

  def create_group_changeset(chatroom, creator, group_name, participants) do
    chat_id = "group:" <> group_name
    all_participants = [creator | participants] |> Enum.uniq()

    chatroom
    |> changeset(%{
      chat_id: chat_id,
      name: group_name,
      type: "group",
      participants: all_participants
    })
  end
end
