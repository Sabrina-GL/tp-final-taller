defmodule AccountsTest do
  use ChatApp.DataCase
  alias ChatApp.Accounts

  setup do
    # Clear database before each test
    ChatApp.Repo.delete_all(ChatApp.Schemas.User)
    ChatApp.Repo.delete_all(ChatApp.Schemas.Message)

    # Clear in-memory metadata for accounts
    case :ets.whereis(:accounts_metadata) do
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

  describe "get_contacts" do
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
  end

  describe "add_contact" do
    setup do
      # Setup test users
      Accounts.register_user("alice", "pass123")
      Accounts.register_user("bob", "pass234")
      :ok
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
      assert {:error, :contact_already_exists} = Accounts.add_contact("alice", "bob")
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

  describe "block_contact" do
    setup do
      # Setup test users
      Accounts.register_user("alice", "pass123")
      Accounts.register_user("bob", "pass234")
      :ok
    end

    test "block_contact blocks interaction and prevents adding contact" do
      assert :ok = Accounts.block_contact("alice", "bob")
      assert {:error, :contact_blocked} = Accounts.add_contact("alice", "bob")
      assert Accounts.interaction_blocked?("alice", "bob")
    end

    test "block_contact rejects self-block" do
      assert {:error, :cannot_block_self} = Accounts.block_contact("alice", "alice")
    end

    test "interaction_blocked? checks bidirectional blocking" do
      Accounts.block_contact("alice", "bob")
      assert Accounts.interaction_blocked?("alice", "bob")
      assert Accounts.interaction_blocked?("bob", "alice")
    end

    test "blocked_with_any? detects if user is blocked with anyone in list" do
      Accounts.register_user("charlie", "pass345")
      Accounts.register_user("dave", "pass456")
      Accounts.block_contact("alice", "bob")
      assert Accounts.blocked_with_any?("alice", ["charlie", "bob", "dave"])
      assert not Accounts.blocked_with_any?("alice", ["charlie", "dave"])
    end

    test "has_blocked_pair? detects blocked pairs in group" do
      Accounts.register_user("charlie", "pass345")
      assert not Accounts.has_blocked_pair?(["alice", "bob", "charlie"])
      Accounts.block_contact("alice", "bob")
      assert Accounts.has_blocked_pair?(["alice", "bob", "charlie"])
    end

    test "has_blocked_pair? returns false for single user" do
      assert not Accounts.has_blocked_pair?(["alice"])
    end
  end

  describe "get_blocked_contacts" do
    setup do
      # Setup test users
      Accounts.register_user("alice", "pass123")
      Accounts.register_user("bob", "pass234")
      :ok
    end

    test "get_blocked_contacts returns list of blocked contacts" do
      Accounts.register_user("charlie", "pass345")
      Accounts.block_contact("alice", "bob")
      Accounts.block_contact("alice", "charlie")
      {:ok, blocked} = Accounts.get_blocked_contacts("alice")
      assert Enum.sort(blocked) == ["bob", "charlie"]
    end

    test "get_blocked_contacts for user with no blocked contacts returns empty list" do
      {:ok, blocked} = Accounts.get_blocked_contacts("bob")
      assert blocked == []
    end

    test "get_blocked_contacts for non-existent user returns error" do
      assert {:error, :user_not_found} = Accounts.get_blocked_contacts("nonexistent")
    end

    test "get_blocked_contacts does not include unblocked contacts" do
      Accounts.register_user("charlie", "pass345")
      Accounts.block_contact("alice", "bob")
      Accounts.block_contact("alice", "charlie")
      Accounts.unblock_contact("alice", "bob")
      {:ok, blocked} = Accounts.get_blocked_contacts("alice")
      assert blocked == ["charlie"]
    end

    test "get_blocked_contacts does not include contacts that were never blocked" do
      Accounts.register_user("charlie", "pass345")
      Accounts.register_user("dave", "pass456")
      Accounts.block_contact("alice", "charlie")
      {:ok, blocked} = Accounts.get_blocked_contacts("alice")
      assert blocked == ["charlie"]
    end
  end

  describe "unblock_contact" do
    setup do
      # Setup test users
      Accounts.register_user("alice", "pass123")
      Accounts.register_user("bob", "pass234")
      :ok
    end

    test "unblock_contact unblocks a previously blocked contact" do
      Accounts.register_user("charlie", "pass345")
      Accounts.block_contact("alice", "charlie")
      assert :ok = Accounts.unblock_contact("alice", "charlie")
      assert not Accounts.interaction_blocked?("alice", "charlie")
    end

    test "unblock_contact with non-blocked contact returns error" do
      assert {:error, :contact_not_blocked} = Accounts.unblock_contact("alice", "bob")
    end

    test "unblock_contact with non-existent user returns error" do
      assert {:error, :user_not_found} = Accounts.unblock_contact("nonexistent", "bob")
    end

    test "unblock_contact with non-existent contact returns error" do
      assert {:error, :user_not_found} = Accounts.unblock_contact("alice", "nonexistent")
    end
  end

  describe "delete_contact" do
    setup do
      # Setup test users
      Accounts.register_user("alice", "pass123")
      Accounts.register_user("bob", "pass234")
      :ok
    end

    test "delete_contact removes contact from user's contact list" do
      Accounts.register_user("charlie", "pass345")
      Accounts.add_contact("alice", "charlie")
      assert :ok = Accounts.delete_contact("alice", "charlie")
      {:ok, contacts} = Accounts.get_contacts("alice")
      assert not Enum.member?(contacts, "charlie")
    end

    test "delete_contact with non-existent user returns error" do
      assert {:error, :user_not_found} = Accounts.delete_contact("nonexistent", "bob")
    end

    test "delete_contact with non-existent contact returns error" do
      assert {:error, :user_not_found} = Accounts.delete_contact("alice", "nonexistent")
    end

    test "delete_contact with non-contact returns error" do
      Accounts.register_user("charlie", "pass345")
      assert {:error, :contact_not_found} = Accounts.delete_contact("alice", "charlie")
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
      assert length(user.contacts) >= 0
      assert length(user.chatrooms) >= 0
    end

    test "get_user returns error for non-existent user" do
      assert {:error, :user_not_found} = Accounts.get_user("nonexistent")
    end
  end
end
