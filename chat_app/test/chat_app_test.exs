defmodule ChatAppTest do
  use ExUnit.Case
  doctest ChatApp

  describe "Accounts" do
    test "register_user creates a new user" do
      {:ok} = ChatApp.Accounts.register_user("testuser", "password123")
      # Verify user was registered
    end

    test "register_user rejects duplicate username" do
      ChatApp.Accounts.register_user("duplicate", "pass1")
      {:error, _reason} = ChatApp.Accounts.register_user("duplicate", "pass2")
    end

    test "authenticate_user validates credentials" do
      ChatApp.Accounts.register_user("authtest", "correctpass")
      {:ok} = ChatApp.Accounts.authenticate_user("authtest", "correctpass")
      {:error, _reason} = ChatApp.Accounts.authenticate_user("authtest", "wrongpass")
    end
  end

  describe "ChatManager" do
    setup do
      # Setup test users
      ChatApp.Accounts.register_user("alice", "pass1")
      ChatApp.Accounts.register_user("bob", "pass2")
      :ok
    end

    test "create_direct_chat creates a chat between two users" do
      {:ok, chat_id} = ChatApp.ChatManager.create_direct_chat("alice", "bob")
      assert is_binary(chat_id)
    end

    test "send_message stores message in chat" do
      {:ok, chat_id} = ChatApp.ChatManager.create_direct_chat("alice", "bob")
      :ok = ChatApp.ChatManager.send_message(chat_id, "alice", "Hello Bob!")
      # Verify message was stored
    end

    test "get_messages retrieves chat history" do
      {:ok, chat_id} = ChatApp.ChatManager.create_direct_chat("alice", "bob")
      ChatApp.ChatManager.send_message(chat_id, "alice", "Message 1")
      ChatApp.ChatManager.send_message(chat_id, "bob", "Message 2")
      messages = ChatApp.ChatManager.get_messages(chat_id, 10)
      assert Enum.count(messages) >= 2
    end

    test "search_messages finds messages by keyword" do
      {:ok, chat_id} = ChatApp.ChatManager.create_direct_chat("alice", "bob")
      ChatApp.ChatManager.send_message(chat_id, "alice", "Hello Elixir")
      ChatApp.ChatManager.send_message(chat_id, "bob", "Hello World")
      results = ChatApp.ChatManager.search_messages(chat_id, "Elixir")
      assert Enum.count(results) >= 1
    end
  end

  describe "ActivityTracker" do
    test "tracks user online status" do
      ChatApp.Accounts.register_user("tracker_test", "pass")
      ChatApp.ActivityTracker.user_online("tracker_test")
      assert ChatApp.ActivityTracker.is_online?("tracker_test")
    end

    test "user marked offline stops showing as online" do
      ChatApp.Accounts.register_user("offline_test", "pass")
      ChatApp.ActivityTracker.user_online("offline_test")
      ChatApp.ActivityTracker.user_offline("offline_test")
      refute ChatApp.ActivityTracker.is_online?("offline_test")
    end
  end
end
