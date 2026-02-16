defmodule ChatManagerTest do
  use ExUnit.Case
  alias ChatApp.{ChatManager, ChatRoom, Accounts}

  setup do
    # Clear database before each test
    ChatApp.Repo.delete_all(ChatApp.Schemas.User)
    ChatApp.Repo.delete_all(ChatApp.Schemas.Message)

    # Clear in-memory metadata for accounts
    case :ets.whereis(:accounts_metadata) do
      :undefined -> :ok
      tid -> :ets.delete_all_objects(tid)
    end

    Registry.unregister_match(ChatApp.ChatRoomsRegistry, :_, :_)

    Accounts.register_user("alice", "pass123")
    Accounts.register_user("bob", "pass234")
    :ok
  end

  describe "get_or_create_private_chat" do
    test "creates a new chat if it doesn't exist" do
      {:ok, chat_id} = ChatManager.get_or_create_private_chat("alice", "bob")
      assert chat_id == "alice:bob"

      # Chequeo que el proceso del chat se haya registrado correctamente
      assert [{pid, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id)
      assert Process.alive?(pid)
    end

    test "returns existing chat if it already exists" do
      {:ok, chat_id1} = ChatManager.get_or_create_private_chat("alice", "bob")
      {:ok, chat_id2} = ChatManager.get_or_create_private_chat("alice", "bob")
      assert chat_id1 == chat_id2

      # Chequeo que no se haya creado un nuevo proceso
      assert [{pid1, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id1)
      assert [{pid2, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id2)
      assert pid1 == pid2
    end

    test "retrieving existing chat in different order returns same chat" do
      {:ok, chat_id1} = ChatManager.get_or_create_private_chat("alice", "bob")
      {:ok, chat_id2} = ChatManager.get_or_create_private_chat("bob", "alice")
      assert chat_id1 == chat_id2

      # Chequeo que no se haya creado un nuevo proceso
      assert [{pid1, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id1)
      assert [{pid2, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id2)
      assert pid1 == pid2
    end

    test "returning existing chat does not create new process" do
      {:ok, chat_id1} = ChatManager.get_or_create_private_chat("alice", "bob")
      {:ok, chat_id2} = ChatManager.get_or_create_private_chat("alice", "bob")

      assert [{pid1, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id1)
      assert [{pid2, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id2)
      assert pid1 == pid2
    end

    test "creating chat with non-existent user returns error" do
      {:error, reason} = ChatManager.get_or_create_private_chat("alice", "charlie")
      {:error, reason2} = ChatManager.get_or_create_private_chat("charlie", "bob")

      assert reason == :user_not_found
      assert reason2 == :user_not_found
    end

    test "creating chat with self returns error" do
      {:error, reason} = ChatManager.get_or_create_private_chat("alice", "alice")
      assert reason == :cannot_chat_with_self
    end

    test "creating chat with users in different order returns same chat" do
      {:ok, chat_id1} = ChatManager.get_or_create_private_chat("alice", "bob")
      {:ok, chat_id2} = ChatManager.get_or_create_private_chat("bob", "alice")
      assert chat_id1 == chat_id2
    end
  end

  describe "create_group_chat" do
    test "create_group_chat creates a new group chat" do
      {:ok, chat_id} =
        ChatManager.create_group_chat("alice", "family", ["bob"])

      assert chat_id == "group:family"

      # Chequeo que el proceso del chat se haya registrado correctamente
      assert [{pid, _}] = Registry.lookup(ChatApp.ChatRoomsRegistry, chat_id)
      assert Process.alive?(pid)
    end
  end

  describe "search_messages" do
    test "search_messages returns error for non-existent chat" do
      {:error, reason} = ChatManager.search_messages("nonexistent_chat", "keyword")
      assert reason == :chat_not_found
    end

    test "search_messages finds messages by keyword" do
      {:ok, chat_id} = ChatManager.get_or_create_private_chat("alice", "bob")
      ChatRoom.add_message(chat_id, "alice", "Hello Elixir")
      ChatRoom.add_message(chat_id, "bob", "Hello World")
      {:ok, results} = ChatManager.search_messages(chat_id, "Elixir")
      assert Enum.count(results) >= 1
    end
  end
end
