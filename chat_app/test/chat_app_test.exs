defmodule ChatAppTest do
  use ExUnit.Case, async: false

  setup do
    case :ets.whereis(:accounts) do
      :undefined -> :ok
      tid -> :ets.delete_all_objects(tid)
    end

    # Clean up any existing chat rooms in Registry
    Registry.select(ChatApp.ChatRoomsRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$2"]}])
    |> Enum.each(fn pid ->
      if Process.alive?(pid), do: Process.exit(pid, :kill)
    end)

    :ok
  end

  describe "Accounts" do
    test "registers and authenticates users with hashing" do
      assert :ok = ChatApp.Accounts.register_user("alice", "pass123")
      assert :ok = ChatApp.Accounts.authenticate_user("alice", "pass123")
      assert {:error, :invalid_credentials} = ChatApp.Accounts.authenticate_user("alice", "wrong")

      {:ok, user} = ChatApp.Accounts.get_user("alice")
      assert user.password != "pass123"
      assert Bcrypt.verify_pass("pass123", user.password)
    end

    test "validates usernames and passwords" do
      assert {:error, :invalid_username} = ChatApp.Accounts.register_user("", "pass123")
      assert {:error, :username_too_short} = ChatApp.Accounts.register_user("ab", "pass123")
      assert {:error, :password_too_short} = ChatApp.Accounts.register_user("validuser", "123")
    end

    test "prevents duplicate usernames" do
      assert :ok = ChatApp.Accounts.register_user("dupuser", "pass123")
      assert {:error, :user_exists} = ChatApp.Accounts.register_user("dupuser", "pass123")
    end
  end

  describe "ActivityTracker" do
    test "tracks user online status and last_seen" do
      ChatApp.Accounts.register_user("tracker_test", "pass123")
      assert :ok = ChatApp.ActivityTracker.user_online("tracker_test")
      assert ChatApp.ActivityTracker.is_online?("tracker_test")
      assert {:ok, _} = ChatApp.ActivityTracker.last_seen("tracker_test")

      assert :ok = ChatApp.ActivityTracker.user_offline("tracker_test")
      refute ChatApp.ActivityTracker.is_online?("tracker_test")
    end

    test "stores and consumes pending notifications" do
      assert :ok = ChatApp.ActivityTracker.add_pending("pending_user", {:new_message, "chat1", %{}})
      assert :ok = ChatApp.ActivityTracker.add_pending("pending_user", {:new_chatroom, "chat2"})

      pending = ChatApp.ActivityTracker.consume_pending("pending_user")
      assert length(pending) == 2
      assert ChatApp.ActivityTracker.consume_pending("pending_user") == []
    end
  end

  describe "ChatManager and ChatRoom" do
    setup do
      ChatApp.Accounts.register_user("bob", "pass123")
      ChatApp.Accounts.register_user("carol", "pass123")
      :ok
    end

    test "creates private chat and stores messages" do
      {:ok, chat_id} = ChatApp.ChatManager.get_or_create_private_chat("bob", "carol")

      message = ChatApp.ChatRoom.add_message(chat_id, "bob", "Hola")
      assert message.from == "bob"

      {:ok, messages} = ChatApp.ChatRoom.get_messages(chat_id)
      assert length(messages) == 1
    end

    test "searches messages in a chat" do
      {:ok, chat_id} = ChatApp.ChatManager.get_or_create_private_chat("bob", "carol")
      ChatApp.ChatRoom.add_message(chat_id, "bob", "Mensaje Elixir")
      ChatApp.ChatRoom.add_message(chat_id, "carol", "Otro texto")

      results = ChatApp.ChatRoom.search_messages(chat_id, "elixir")
      assert length(results) == 1
    end

    test "rejects messages from non participants" do
      ChatApp.Accounts.register_user("eve", "pass123")
      {:ok, chat_id} = ChatApp.ChatManager.get_or_create_private_chat("bob", "carol")

      assert {:error, :not_participant} = ChatApp.ChatRoom.add_message(chat_id, "eve", "intruso")
    end

    test "creates group chat" do
      {:ok, chat_id} = ChatApp.ChatManager.create_group_chat("bob", "grupo1", ["carol"])
      assert String.starts_with?(chat_id, "group:")
    end
  end
end
