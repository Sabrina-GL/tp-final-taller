defmodule ChatApp.Schemas.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :chat_id, :string
    field :from_user, :string
    field :content, :string
    field :timestamp, :naive_datetime

    # File attachment fields
    field :file_type, :string
    field :file_name, :string
    field :file_path, :string
    field :file_size, :integer

    belongs_to :user, ChatApp.Schemas.User, foreign_key: :user_id, type: :id

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:chat_id, :from_user, :content, :timestamp, :user_id,
                    :file_type, :file_name, :file_path, :file_size])
    |> validate_required([:chat_id, :from_user, :timestamp])
    |> validate_content_or_file()
    |> validate_length(:content, min: 1, max: 1024)
    |> validate_length(:file_name, max: 255)
    |> validate_number(:file_size, less_than_or_equal_to: 5_242_880)
  end

  defp validate_content_or_file(changeset) do
    content = get_field(changeset, :content)
    file_path = get_field(changeset, :file_path)

    if is_nil(content) and is_nil(file_path) do
      add_error(changeset, :content, "content or file must be present")
    else
      changeset
    end
  end

  @doc false
  def create_changeset(message, attrs) do
    message
    |> changeset(attrs)
    |> put_change(:timestamp, attrs[:timestamp] || NaiveDateTime.utc_now())
  end
end
