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
end
