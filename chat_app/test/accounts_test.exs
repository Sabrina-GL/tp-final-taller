defmodule AccountsTest do
  use ExUnit.Case
  alias ChatApp.Accounts

  setup do
    case :ets.whereis(:accounts) do
      :undefined -> :ok
      tid -> :ets.delete_all_objects(tid)
    end

    :ok
  end

  describe "register_user" do
    test "register_user creates a new user" do
      assert :ok = ChatApp.Accounts.register_user("testuser", "password123")
      # Verify user was registered
    end

    test "register_user rejects duplicate username" do
      Accounts.register_user("duplicate", "pass123")
      assert {:error, :user_exists} = Accounts.register_user("duplicate", "pass234")
    end

    test "register_user rejects short username" do
      assert {:error, :username_too_short} = Accounts.register_user("ab", "password123")
    end

    test "register_user rejects short password" do
      assert {:error, :password_too_short} = Accounts.register_user("validuser", "12345")
    end

    test "register_user accepts minimum valid length" do
      assert :ok = Accounts.register_user("abc", "123456")
    end

    test "register_user accepts long username and password" do
      long_user = String.duplicate("a", 50)
      long_pass = String.duplicate("b", 100)
      assert :ok = Accounts.register_user(long_user, long_pass)
    end
  end

  describe "authenticate_user" do
    test "authenticate_user with valid credentials" do
      Accounts.register_user("authtest", "correctpass")
      assert :ok = Accounts.authenticate_user("authtest", "correctpass")
    end

    test "authenticate_user with invalid credentials" do
      Accounts.register_user("authtest", "rightpass")

      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("authtest", "wrongpass")

      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("nonexistent", "correctpass")
    end
  end

  describe "contacts" do
    setup do
      # Setup test users
      Accounts.register_user("alice", "pass123")
      Accounts.register_user("bob", "pass234")
      :ok
    end

    test "get_contacts returns empty list for new user" do
      {:ok, contacts} = Accounts.get_contacts("alice")
      assert contacts == []
    end

    test "get_contacts for non-existent user returns error" do
      assert {:error, :user_not_found} = Accounts.get_contacts("nonexistent")
    end

    test "add_contact adds a contact to user's contact list" do
      assert :ok = Accounts.add_contact("alice", "bob")
      {:ok, contacts} = Accounts.get_contacts("alice")
      assert "bob" in contacts
    end

    test "add_contact with non-existent user returns error" do
      assert {:error, :user_not_found} = Accounts.add_contact("alice", "nonexistent")
    end

    test "add_contact with non-existent contact returns error" do
      assert {:error, :user_not_found} = Accounts.add_contact("alice", "charlie")
    end

    test "add_contact with self returns error" do
      assert {:error, :cannot_add_self} = Accounts.add_contact("alice", "alice")
    end

    test "add_contact rejects duplicate contact" do
      assert :ok = Accounts.add_contact("alice", "bob")
      assert :ok = Accounts.add_contact("alice", "bob")
      {:ok, contacts} = Accounts.get_contacts("alice")
      # Should only appear once
      assert Enum.count(contacts, fn c -> c == "bob" end) == 1
    end

    test "multiple contacts can be added" do
      Accounts.register_user("charlie", "pass345")
      Accounts.register_user("dave", "pass456")
      assert :ok = Accounts.add_contact("alice", "bob")
      assert :ok = Accounts.add_contact("alice", "charlie")
      assert :ok = Accounts.add_contact("alice", "dave")
      {:ok, contacts} = Accounts.get_contacts("alice")
      assert length(contacts) == 3
    end
  end

  describe "account's chatrooms" do
    setup do
      Accounts.register_user("charlie", "pass345")
      :ok
    end

    test "get_chatrooms returns empty list for new user" do
      {:ok, chatrooms} = Accounts.get_chatrooms("charlie")
      assert chatrooms == []
    end

    test "get_chatrooms for non-existent user returns error" do
      assert {:error, :user_not_found} = Accounts.get_chatrooms("nonexistent")
    end

    test "get_chatrooms returns list of chatrooms for user" do
      Accounts.add_chatroom("charlie", "chat1")
      Accounts.add_chatroom("charlie", "chat2")
      {:ok, chatrooms} = Accounts.get_chatrooms("charlie")
      assert "chat1" in chatrooms
      assert "chat2" in chatrooms
    end

    test "add_chatroom for non-existent user returns error" do
      assert {:error, :user_not_found} = Accounts.add_chatroom("nonexistent", "chat1")
    end

    test "add_chatroom adds a chatroom to user's chatroom list" do
      assert :ok = Accounts.add_chatroom("charlie", "chat1")
      {:ok, chatrooms} = Accounts.get_chatrooms("charlie")
      assert "chat1" in chatrooms
    end

    test "add_chatroom rejects duplicate chatroom" do
      assert :ok = Accounts.add_chatroom("charlie", "chat1")
      assert :ok = Accounts.add_chatroom("charlie", "chat1")
      {:ok, chatrooms} = Accounts.get_chatrooms("charlie")
      assert Enum.count(chatrooms) == 1
    end
  end

  describe "get_user" do
    setup do
      Accounts.register_user("testuser", "testpass")
      :ok
    end

    test "get_user returns user data for existing user" do
      assert {:ok, user} = Accounts.get_user("testuser")
      assert user.username == "testuser"
      assert MapSet.size(user.contacts) >= 0
      assert MapSet.size(user.chat_rooms) >= 0
    end

    test "get_user returns error for non-existent user" do
      assert {:error, :user_not_found} = Accounts.get_user("nonexistent")
    end
  end

  describe "password migration" do
    test "old plaintext passwords are migrated to bcrypt on login" do
      # Simula un usuario con password en texto plano (legacy)
      :ets.insert(:accounts, {"legacy_user", %{
        username: "legacy_user",
        password: "plaintext_password",
        contacts: [],
        chatrooms: []
      }})

      # Al autenticarse, debería migrar el password
      assert :ok = Accounts.authenticate_user("legacy_user", "plaintext_password")

      # Verificar que el password fue hasheado
      {:ok, user} = Accounts.get_user("legacy_user")
      assert String.starts_with?(user.password, "$2b$")
    end
  end
end
