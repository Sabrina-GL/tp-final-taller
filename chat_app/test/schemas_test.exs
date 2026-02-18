defmodule ChatApp.SchemasTest do
  use ChatApp.DataCase
  alias ChatApp.Schemas.{Message, User, Contact, Chatroom}
  alias ChatApp.Repo

  setup do
    # Clear database before each test
    Repo.delete_all(Message)
    Repo.delete_all(Contact)
    Repo.delete_all(Chatroom)
    Repo.delete_all(User)
    :ok
  end

  describe "Message schema" do
    test "changeset validates required fields" do
      changeset = Message.changeset(%Message{}, %{})
      assert not changeset.valid?
      assert :chat_id in Keyword.keys(changeset.errors)
      assert :from_user in Keyword.keys(changeset.errors)
      assert :content in Keyword.keys(changeset.errors)
      assert :timestamp in Keyword.keys(changeset.errors)
    end

    test "changeset with valid fields is valid" do
      changeset = Message.changeset(%Message{}, %{
        chat_id: "test",
        from_user: "alice",
        content: "Valid message",
        timestamp: NaiveDateTime.utc_now()
      })
      assert changeset.valid?
    end

    test "changeset validates content length minimum" do
      changeset = Message.changeset(%Message{}, %{
        chat_id: "test",
        from_user: "alice",
        content: "",
        timestamp: NaiveDateTime.utc_now()
      })
      assert not changeset.valid?
      assert :content in Keyword.keys(changeset.errors)
    end

    test "changeset validates content length maximum" do
      long_content = String.duplicate("a", 1025)
      changeset = Message.changeset(%Message{}, %{
        chat_id: "test",
        from_user: "alice",
        content: long_content,
        timestamp: NaiveDateTime.utc_now()
      })
      assert not changeset.valid?
      assert :content in Keyword.keys(changeset.errors)
    end

    test "create_changeset uses provided timestamp" do
      ts = NaiveDateTime.utc_now()
      changeset = Message.create_changeset(%Message{}, %{
        chat_id: "test",
        from_user: "alice",
        content: "Hola",
        timestamp: ts
      })
      assert changeset.valid?
      assert changeset.changes[:timestamp] == ts
    end
  end

  describe "Contact schema" do
    setup do
      {:ok, alice} = Repo.insert(User.changeset(%User{}, %{
        username: "alice",
        password_hash: "hash"
      }))
      {:ok, bob} = Repo.insert(User.changeset(%User{}, %{
        username: "bob",
        password_hash: "hash"
      }))
      %{alice: alice, bob: bob}
    end

    test "contact with active status is valid", context do
      changeset = Contact.changeset(%Contact{}, %{
        user_id: context.alice.id,
        contact_id: context.bob.id,
        status: "active"
      })
      assert changeset.valid?
    end

    test "contact with blocked status is valid", context do
      changeset = Contact.changeset(%Contact{}, %{
        user_id: context.alice.id,
        contact_id: context.bob.id,
        status: "blocked"
      })
      assert changeset.valid?
    end

    test "contact with invalid status is invalid", context do
      changeset = Contact.changeset(%Contact{}, %{
        user_id: context.alice.id,
        contact_id: context.bob.id,
        status: "invalid_status"
      })
      assert not changeset.valid?
      assert :status in Keyword.keys(changeset.errors)
    end

    test "contact validates required fields", _context do
      changeset = Contact.changeset(%Contact{}, %{
        status: "active"
      })
      assert not changeset.valid?
      assert :user_id in Keyword.keys(changeset.errors)
      assert :contact_id in Keyword.keys(changeset.errors)
    end
  end

  describe "Chatroom schema" do
    test "chatroom is created with valid fields" do
      changeset = Chatroom.changeset(%Chatroom{}, %{
        chat_id: "chat-123",
        type: "private",
        participants: ["alice", "bob"]
      })
      assert changeset.valid?
    end

    test "chatroom validates required fields" do
      changeset = Chatroom.changeset(%Chatroom{}, %{})
      assert not changeset.valid?
      assert :chat_id in Keyword.keys(changeset.errors)
    end

    test "chatroom validates type inclusion" do
      changeset = Chatroom.changeset(%Chatroom{}, %{
        chat_id: "test",
        type: "invalid_type",
        participants: ["alice", "bob"]
      })
      assert not changeset.valid?
      assert :type in Keyword.keys(changeset.errors)
    end

    test "chatroom validates participants minimum length" do
      changeset = Chatroom.changeset(%Chatroom{}, %{
        chat_id: "test",
        type: "private",
        participants: ["alice"]
      })
      assert not changeset.valid?
      assert :participants in Keyword.keys(changeset.errors)
    end
  end
end
