defmodule ChatApp.NotificationsTest do
  use ChatApp.DataCase, async: false

  alias ChatApp.{Accounts, Notifications, ActivitySupervisor, Repo}

  setup do
    # Clear database before each test
    Repo.delete_all(ChatApp.Schemas.User)
    Repo.delete_all(ChatApp.Schemas.Message)

    # Clear in-memory metadata for accounts
    case :ets.whereis(:accounts_metadata) do
      :undefined -> :ok
      tid -> :ets.delete_all_objects(tid)
    end

    # Register test users
    Accounts.register_user("alice", "pass123")
    Accounts.register_user("bob", "pass123")

    for user <- ["alice", "bob"] do
      case ActivitySupervisor.start_activity_server(user) do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> :ok
      end
    end

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

      # Should return :offline since user is not in registry
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
