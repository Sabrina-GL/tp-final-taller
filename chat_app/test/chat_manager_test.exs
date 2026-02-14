defmodule ChatManagerTest do
  use ExUnit.Case
  alias ChatApp.{ChatManager, ChatRoom, Accounts}

  setup do
    # if Process.whereis(ChatManager) do
    #   GenServer.stop(ChatManager)
    # end
    {:ok, _} = Application.ensure_all_started(:chat_app)

    # if Process.whereis(Accounts) do
    #   GenServer.stop(Accounts)
    # end

    Registry.unregister_match(ChatApp.ChatRoomsRegistry, :_, :_)
    # {:ok, _pid} = ChatManager.start_link(nil)
    # {:ok, _pid} = Accounts.start_link(nil)

    Accounts.register_user("alice", "pass1")
    Accounts.register_user("bob", "pass2")
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

    test "add chatroom to users when creating private chat" do
      {:ok, chat_id} = ChatManager.get_or_create_private_chat("alice", "bob")

      # Verifico que el chat se haya agregado a ambos usuarios
      {:ok, alice_chatrooms} = Accounts.get_chatrooms("alice")
      {:ok, bob_chatrooms} = Accounts.get_chatrooms("bob")

      assert chat_id in alice_chatrooms
      assert chat_id in bob_chatrooms
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
