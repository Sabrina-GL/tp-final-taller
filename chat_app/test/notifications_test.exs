defmodule ChatApp.NotificationsTest do
  use ChatApp.DataCase, async: false
  alias ChatApp.Notifications

  setup do
    create_test_users(["alice", "bob"])
    start_activity_servers(["alice", "bob"])
    :ok
  end

  describe "notify_new_chatroom" do
    test "sends notification to online user" do
      # Simulate online user by registering in UsersRegistry
      Registry.register(ChatApp.UsersRegistry, "alice", self())

      result = ChatApp.Notifications.notify_new_chatroom("alice", "test_chat")

      assert result == :ok
      assert_receive {:new_chatroom, "test_chat"}, 1000
    end

    test "queues notification via ActivityServer when user offline" do
      # User not registered in Registry = offline
      ChatApp.ActivityServer.user_offline("bob")
      Registry.unregister(ChatApp.UsersRegistry, "bob")

      result = Notifications.notify_new_chatroom("bob", "test_chat")

      assert result == :offline
    end
  end

  describe "notify_new_message" do
    test "sends message notification to online user" do
      Registry.register(ChatApp.UsersRegistry, "alice", self())

      message = %{from: "bob", msg_content: "Hello!", timestamp: DateTime.utc_now()}
      Notifications.notify_new_message("alice", "test_chat", message)

      assert_receive {:new_message, "test_chat", ^message}, 1000
    end

    test "returns :offline when user not registered" do
      message = %{from: "alice", msg_content: "Hi!", timestamp: DateTime.utc_now()}

      result = Notifications.notify_new_message("bob", "test_chat", message)

      assert result == :offline
    end
  end
end
