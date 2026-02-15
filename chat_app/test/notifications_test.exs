defmodule ChatApp.NotificationsTest do
  use ExUnit.Case, async: false

  setup do
    # Clear ETS table before each test
    case :ets.whereis(:accounts) do
      :undefined -> :ok
      tid -> :ets.delete_all_objects(tid)
    end

    # Register test users
    ChatApp.Accounts.register_user("alice", "pass123")
    ChatApp.Accounts.register_user("bob", "pass123")
    :ok
  end

  describe "notify_new_chatroom" do
    test "sends notification to online user" do
      # Simulate online user by registering in UsersRegistry
      Registry.register(ChatApp.UsersRegistry, "alice", self())

      ChatApp.Notifications.notify_new_chatroom("alice", "test_chat")

      assert_receive {:new_chatroom, "test_chat"}, 1000
    end

    test "queues notification via ActivityTracker when user offline" do
      # User not registered in Registry = offline
      ChatApp.ActivityTracker.user_offline("bob")

      result = ChatApp.Notifications.notify_new_chatroom("bob", "test_chat")

      # Should return :offline since user is not in registry
      assert result == :offline
    end
  end

  describe "notify_new_message" do
    test "sends message notification to online user" do
      Registry.register(ChatApp.UsersRegistry, "alice", self())

      message = %{from: "bob", msg_content: "Hello!", timestamp: DateTime.utc_now()}
      ChatApp.Notifications.notify_new_message("alice", "test_chat", message)

      assert_receive {:new_message, "test_chat", ^message}, 1000
    end

    test "returns :offline when user not registered" do
      message = %{from: "alice", msg_content: "Hi!", timestamp: DateTime.utc_now()}

      result = ChatApp.Notifications.notify_new_message("bob", "test_chat", message)

      assert result == :offline
    end
  end
end
