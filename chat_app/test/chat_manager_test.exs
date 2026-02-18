defmodule ChatManagerTest do
  use ChatApp.DataCase
  alias ChatApp.{ChatManager, Accounts, Repo}

  setup do
    # Clear database before each test
    ChatApp.Repo.delete_all(ChatApp.Schemas.User)
    ChatApp.Repo.delete_all(ChatApp.Schemas.Message)
    ChatApp.Repo.delete_all(ChatApp.Schemas.Chatroom)

    # Clear in-memory metadata for accounts
    # case :ets.whereis(:accounts_metadata) do
    #   :undefined -> :ok
    #   tid -> :ets.delete_all_objects(tid)
    # end

    # Registry.unregister_match(ChatApp.ChatRoomsRegistry, :_, :_)

    Accounts.register_user("alice", "pass123")
    Accounts.register_user("bob", "pass234")

    Enum.each(["alice", "bob"], fn user ->
      case ChatApp.ActivitySupervisor.start_activity_server(user) do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> :ok
      end
    end)

    :ok
  end

  describe "create_private_chat" do
    test "creates a new chat if it doesn't exist" do
      {:ok, chat_id} = ChatManager.create_private_chat("alice", "bob")
      assert chat_id == "alice:bob"

      # Chequeo que el proceso del chat se haya registrado correctamente
      assert [{pid, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id)
      assert Process.alive?(pid)
    end

    test "returns existing chat if it already exists" do
      {:ok, chat_id1} = ChatManager.create_private_chat("alice", "bob")
      {:ok, chat_id2} = ChatManager.create_private_chat("alice", "bob")
      assert chat_id1 == chat_id2

      # Chequeo que no se haya creado un nuevo proceso
      assert [{pid1, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id1)
      assert [{pid2, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id2)
      assert pid1 == pid2
    end

    test "retrieving existing chat in different order returns same chat" do
      {:ok, chat_id1} = ChatManager.create_private_chat("alice", "bob")
      {:ok, chat_id2} = ChatManager.create_private_chat("bob", "alice")
      assert chat_id1 == chat_id2

      # Chequeo que no se haya creado un nuevo proceso
      assert [{pid1, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id1)
      assert [{pid2, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id2)
      assert pid1 == pid2
    end

    test "creating chat with non-existent user returns error" do
      {:error, reason} = ChatManager.create_private_chat("alice", "charlie")
      {:error, reason2} = ChatManager.create_private_chat("charlie", "bob")

      assert reason == :user_not_found
      assert reason2 == :user_not_found
    end

    test "creating chat with self returns error" do
      {:error, reason} = ChatManager.create_private_chat("alice", "alice")
      assert reason == :cannot_chat_with_self
    end

    test "creating chat with users in different order returns same chat" do
      {:ok, chat_id1} = ChatManager.create_private_chat("alice", "bob")
      {:ok, chat_id2} = ChatManager.create_private_chat("bob", "alice")
      assert chat_id1 == chat_id2
    end

    test "creating private chat with blocked contact returns error" do
      assert :ok = Accounts.block_contact("alice", "bob")
      assert {:error, :contact_blocked} = ChatManager.create_private_chat("alice", "bob")
    end
  end

  describe "create_group_chat" do
    test "create_group_chat creates a new group chat" do
      {:ok, chat_id} =
        ChatManager.create_group_chat("alice", "family", ["bob"])

      chatroom = Repo.get_by(ChatApp.Schemas.Chatroom, chat_id: chat_id)

      assert chat_id == "group:family"

      # Chequeo que el proceso del chat se haya registrado correctamente
      assert [{pid, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id)
      assert Process.alive?(pid)
      assert chatroom.name == "family"
      assert Enum.sort(chatroom.participants) == ["alice", "bob"]
    end

    test "create_group_chat with non-existent participant returns error" do
      {:error, reason} =
        ChatManager.create_group_chat("alice", "friends", ["charlie"])

      assert reason == :user_not_found
    end

    test "create_group_chat with existing group name returns error" do
      {:ok, _chat_id} =
        ChatManager.create_group_chat("alice", "work", ["bob"])

      {:error, reason} =
        ChatManager.create_group_chat("bob", "work", ["alice"])

      assert reason == :group_name_taken
    end

    test "create_group_chat with duplicate participants only adds once" do
      {:ok, chat_id} =
        ChatManager.create_group_chat("alice", "duplicates", ["bob", "bob"])

      chatroom = Repo.get_by(ChatApp.Schemas.Chatroom, chat_id: chat_id)
      assert chatroom.participants == ["alice", "bob"]
    end

    test "create_group_chat with creator as participant only adds once" do
      {:ok, chat_id} =
        ChatManager.create_group_chat("alice", "self_duplicate", ["alice", "bob"])

      chatroom = Repo.get_by(ChatApp.Schemas.Chatroom, chat_id: chat_id)
      assert chatroom.participants == ["alice", "bob"]
    end

    test "create_group_chat with blocked participants returns error" do
      Accounts.register_user("carol", "pass555")
      assert :ok = Accounts.block_contact("bob", "carol")

      assert {:error, :contact_blocked} =
               ChatManager.create_group_chat("alice", "team_blocked", ["bob", "carol"])
    end
  end

  describe "get_user_chatrooms" do
    test "get_user_chatrooms returns empty list for user with no chats" do
      chatrooms = ChatManager.get_user_chatrooms("alice")
      assert chatrooms == []
    end

    test "get_user_chatrooms returns list of chatrooms for user" do
      {:ok, chat_id} = ChatManager.create_private_chat("alice", "bob")
      chatrooms = ChatManager.get_user_chatrooms("alice")
      assert chatrooms == [chat_id]
    end

    test "get_user_chatrooms returns error for non-existent user" do
      chatrooms = ChatManager.get_user_chatrooms("charlie")
      assert chatrooms == {:error, :user_not_found}
    end

    test "get_user_chatrooms returns multiple chatrooms for user" do
      {:ok, chat_id1} = ChatManager.create_private_chat("alice", "bob")
      {:ok, chat_id2} = ChatManager.create_group_chat("alice", "group1", ["bob"])
      chatrooms = ChatManager.get_user_chatrooms("alice")
      assert Enum.sort(chatrooms) == Enum.sort([chat_id1, chat_id2])
    end
  end

  # describe "search_messages" do
  #   test "search_messages returns error for non-existent chat" do
  #     {:error, reason} = ChatManager.search_messages("nonexistent_chat", "keyword")
  #     assert reason == :chat_not_found
  #   end

  #   test "search_messages finds messages by keyword" do
  #     {:ok, chat_id} = ChatManager.get_or_create_private_chat("alice", "bob")
  #     ChatRoom.add_message(chat_id, "alice", "Hello Elixir")
  #     ChatRoom.add_message(chat_id, "bob", "Hello World")
  #     {:ok, results} = ChatManager.search_messages(chat_id, "Elixir")
  #     assert Enum.count(results) >= 1
  #   end
end
