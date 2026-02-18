defmodule ChatWeb.SocketHandlerBasicTest do
  use ExUnit.Case, async: false
  alias ChatWeb.SocketHandler

  setup do
    # Clear database before each test
    ChatApp.Repo.delete_all(ChatApp.Schemas.User)
    ChatApp.Repo.delete_all(ChatApp.Schemas.Message)
    ChatApp.Repo.delete_all(ChatApp.Schemas.Chatroom)

    # Clear in-memory metadata for accounts
    case :ets.whereis(:accounts_metadata) do
      :undefined -> :ok
      tid -> :ets.delete_all_objects(tid)
    end

    try do
      Registry.unregister_match(ChatApp.UsersRegistry, :_, :_)
    rescue
      _e -> :ok
    end

    Registry.select(ChatApp.ChatRoomsRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$2"]}])
    |> Enum.each(fn pid -> if Process.alive?(pid), do: Process.exit(pid, :kill) end)

    Registry.unregister_match(ChatApp.ChatRoomsRegistry, :_, :_)

    # Iniciar o reutilizar ActivityServer para cada usuario de test
    case ChatApp.ActivityServer.start_link("alice") do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
    case ChatApp.ActivityServer.start_link("bob") do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
    case ChatApp.ActivityServer.start_link("carol") do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    # Resetear estado inicial de los usuarios
    ChatApp.ActivityServer.consume_pending("alice")
    ChatApp.ActivityServer.user_offline("alice")
    ChatApp.ActivityServer.consume_pending("bob")
    ChatApp.ActivityServer.user_offline("bob")
    ChatApp.ActivityServer.consume_pending("carol")
    ChatApp.ActivityServer.user_offline("carol")

    :ok
  end

  test "websocket_handle returns error on unknown action" do
    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "unknown"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["error"] == "unknown_action"
  end

  test "websocket_handle get_contacts returns empty list" do
    ChatApp.Accounts.register_user("alice", "pass123")
    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "get_contacts"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["contacts"] == []
  end

  test "websocket_handle get_chatrooms returns empty list" do
    ChatApp.Accounts.register_user("alice", "pass123")
    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "get_chatrooms"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["chatrooms"] == []
  end

  test "websocket_handle add_contact returns error when user missing" do
    ChatApp.Accounts.register_user("alice", "pass123")
    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "add_contact", "contact" => "bob"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["error"] == "user_not_found"
  end

  test "websocket_handle add_contact succeeds and opens chat" do
    ChatApp.Accounts.register_user("alice", "pass123")
    ChatApp.Accounts.register_user("bob", "pass123")
    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "add_contact", "contact" => "bob"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "contact_added"
    assert data["chat_opened"] == true
    assert data["chat_id"] == "alice:bob"
  end

  test "websocket_handle block_contact blocks user" do
    ChatApp.Accounts.register_user("alice", "pass123")
    ChatApp.Accounts.register_user("bob", "pass123")
    state = %{user: "alice"}

    msg = Jason.encode!(%{"action" => "block_contact", "contact" => "bob"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "contact_blocked"
    assert data["contact"] == "bob"
  end

  test "websocket_handle get_status returns online status" do
    ChatApp.Accounts.register_user("alice", "pass123")
    ChatApp.ActivityServer.user_online("alice")

    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "get_status"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["user"] == "alice"
    assert data["online"] == true
    assert is_integer(data["last_seen"])
  end

  test "websocket_handle get_messages returns messages list" do
    ChatApp.Accounts.register_user("alice", "pass123")
    ChatApp.Accounts.register_user("bob", "pass123")

    {:ok, chat_id} = ChatApp.ChatManager.create_private_chat("alice", "bob")
    ChatApp.ChatRoomServer.add_message(chat_id, "alice", "Hola")

    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "get_messages", "chat_id" => chat_id})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert length(data["messages"]) == 1
  end

  test "websocket_handle create_group_chat returns success" do
    ChatApp.Accounts.register_user("alice", "pass123")
    ChatApp.Accounts.register_user("bob", "pass123")
    ChatApp.Accounts.register_user("carol", "pass123")

    group_name = "team_#{System.unique_integer([:positive])}"
    state = %{user: "alice"}

    msg =
      Jason.encode!(%{
        "action" => "create_group_chat",
        "group_name" => group_name,
        "participants" => ["bob", "carol"]
      })

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "group_chat_created"
    assert data["group_name"] == group_name
  end

  test "websocket_handle send_message returns error when not participant" do
    ChatApp.Accounts.register_user("alice", "pass123")
    ChatApp.Accounts.register_user("bob", "pass123")
    ChatApp.Accounts.register_user("carol", "pass123")

    {:ok, chat_id} = ChatApp.ChatManager.create_private_chat("bob", "carol")

    state = %{user: "alice"}

    msg =
      Jason.encode!(%{
        "action" => "send_message",
        "chat_id" => chat_id,
        "msg_content" => "Nope"
      })

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "error"
    assert data["error"] == "not_participant"
  end

  test "websocket_handle send_message returns message on success" do
    ChatApp.Accounts.register_user("alice", "pass123")
    ChatApp.Accounts.register_user("bob", "pass123")

    {:ok, chat_id} = ChatApp.ChatManager.create_private_chat("alice", "bob")

    state = %{user: "alice"}

    msg =
      Jason.encode!(%{
        "action" => "send_message",
        "chat_id" => chat_id,
        "msg_content" => "Hello"
      })

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "ok"
    assert data["message"]["msg_content"] == "Hello"
  end

  test "websocket_handle delete_message deletes an existing message" do
    ChatApp.Accounts.register_user("alice", "pass123")
    ChatApp.Accounts.register_user("bob", "pass123")

    {:ok, chat_id} = ChatApp.ChatManager.create_private_chat("alice", "bob")
    message = ChatApp.ChatRoomServer.add_message(chat_id, "alice", "Delete me")

    state = %{user: "alice"}

    msg =
      Jason.encode!(%{
        "action" => "delete_message",
        "chat_id" => chat_id,
        "message_id" => message.id
      })

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "message_deleted"
    assert data["message_id"] == message.id
  end

  test "websocket_info new_chatroom returns payload" do
    state = %{user: "alice"}

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_info({:new_chatroom, "room1"}, state)

    data = Jason.decode!(reply)
    assert data["type"] == "new_chatroom"
    assert data["chat_id"] == "room1"
  end

  test "websocket_info new_message returns payload" do
    state = %{user: "alice"}
    message = %{from: "bob", msg_content: "hi"}

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_info({:new_message, "room1", message}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "new_message"
    assert data["chat_id"] == "room1"
    assert data["message"]["msg_content"] == "hi"
  end

  test "websocket_info ignores unknown info" do
    state = %{user: "alice"}
    assert {:ok, ^state} = SocketHandler.websocket_info(:unknown, state)
  end

  test "terminate marks user offline" do
    ChatApp.Accounts.register_user("alice", "pass123")
    ChatApp.ActivityServer.user_online("alice")

    assert :ok = SocketHandler.terminate(:normal, nil, %{user: "alice"})
    assert ChatApp.ActivityServer.is_online?("alice") == false
  end

  test "websocket_init registers user and flushes pending" do
    ChatApp.Accounts.register_user("alice", "pass123")
    ChatApp.ActivityServer.add_pending("alice", {:new_chatroom, "room1"})

    assert {:ok, %{user: "alice"}} = SocketHandler.websocket_init(%{user: "alice"})
    assert Registry.lookup(ChatApp.UsersRegistry, "alice") != []
    assert_receive {:new_chatroom, "room1"}
  end

  test "websocket_handle ignores non-text frames" do
    state = %{user: "alice"}
    assert {:ok, ^state} = SocketHandler.websocket_handle({:binary, "x"}, state)
  end
end
