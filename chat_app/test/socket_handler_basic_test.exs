defmodule ChatWeb.SocketHandlerBasicTest do
  use ChatApp.DataCase, async: false
  alias ChatWeb.SocketHandler

  setup do
    create_test_users(["alice", "bob", "carol"])
    start_activity_servers(["alice", "bob", "carol"])
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
    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "get_contacts"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["contacts"] == []
  end

  test "websocket_handle get_contacts oculta presencia cuando existe bloqueo" do
    assert :ok = ChatApp.Accounts.add_contact("alice", "bob")
    assert :ok = ChatApp.Accounts.block_contact("bob", "alice")
    assert :ok = ChatApp.ActivityServer.user_online("bob")

    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "get_contacts"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    bob = Enum.find(data["contacts"], fn contact -> contact["username"] == "bob" end)

    assert bob != nil
    assert bob["online"] == false
  end

  test "websocket_handle get_chatrooms returns empty list" do
    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "get_chatrooms"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["chatrooms"] == []
  end

  test "websocket_handle add_contact returns error when user missing" do
    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "add_contact", "contact" => "bobless"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["error"] == "user_not_found"
  end

  test "websocket_handle add_contact succeeds and opens chat" do
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
    state = %{user: "alice"}

    msg = Jason.encode!(%{"action" => "block_contact", "contact" => "bob"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "contact_blocked"
    assert data["contact"] == "bob"
  end

  test "websocket_handle get_blocked_contacts devuelve bloqueados" do
    :ok = ChatApp.Accounts.block_contact("alice", "bob")

    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "get_blocked_contacts"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert "bob" in data["blocked_contacts"]
  end

  test "websocket_handle unblock_contact desbloquea usuario" do
    :ok = ChatApp.Accounts.block_contact("alice", "bob")
    state = %{user: "alice"}

    msg = Jason.encode!(%{"action" => "unblock_contact", "contact" => "bob"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "contact_unblocked"
    assert data["contact"] == "bob"
  end

  test "websocket_handle delete_contact elimina contacto" do
    assert :ok = ChatApp.Accounts.add_contact("alice", "bob")
    state = %{user: "alice"}

    msg = Jason.encode!(%{"action" => "delete_contact", "contact" => "bob"})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "contact_deleted"
    assert data["contact"] == "bob"
  end

  test "websocket_handle get_status returns online status" do
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
    {:ok, chat_id} = ChatApp.ChatManager.create_private_chat("alice", "bob")
    ChatApp.ChatRoomServer.add_message(chat_id, "alice", "Hola")

    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "get_messages", "chat_id" => chat_id})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert length(data["messages"]) == 1
  end

  test "websocket_handle get_messages returns ISO UTC timestamps" do
    {:ok, chat_id} = ChatApp.ChatManager.create_private_chat("alice", "bob")
    ChatApp.ChatRoomServer.add_message(chat_id, "alice", "Primero")
    ChatApp.ChatRoomServer.add_message(chat_id, "bob", "Segundo")

    state = %{user: "alice"}
    msg = Jason.encode!(%{"action" => "get_messages", "chat_id" => chat_id})

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert length(data["messages"]) == 2

    Enum.each(data["messages"], fn message ->
      assert is_binary(message["timestamp"])
      assert String.ends_with?(message["timestamp"], "Z")

      assert {:ok, _datetime, 0} = DateTime.from_iso8601(message["timestamp"])
    end)
  end

  test "websocket_handle create_group_chat returns success" do
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

  test "websocket_handle send_file guarda adjunto y responde ok" do
    {:ok, chat_id} = ChatApp.ChatManager.create_private_chat("alice", "bob")
    file_content = Base.encode64("contenido de archivo")

    state = %{user: "alice"}

    msg =
      Jason.encode!(%{
        "action" => "send_file",
        "chat_id" => chat_id,
        "file_content" => file_content,
        "file_name" => "prueba.txt",
        "file_type" => "text/plain"
      })

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "ok"
    assert data["type"] == "file"
    assert data["message"]["file_name"] == "prueba.txt"
    assert is_integer(data["message"]["file_size"])
    assert is_binary(data["message"]["file_path"])

    assert :ok = ChatApp.FileManager.delete_file(data["message"]["file_path"])
  end

  test "websocket_handle send_file retorna error cuando falta file_name" do
    {:ok, chat_id} = ChatApp.ChatManager.create_private_chat("alice", "bob")
    state = %{user: "alice"}

    msg =
      Jason.encode!(%{
        "action" => "send_file",
        "chat_id" => chat_id,
        "file_content" => Base.encode64("abc"),
        "file_type" => "text/plain"
      })

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, msg}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "error"
    assert data["error"] == "Missing required field: file_name"
  end

  test "websocket_handle delete_message deletes an existing message" do
    assert {:ok, _} = ChatApp.Accounts.get_user("alice")
    assert {:ok, _} = ChatApp.Accounts.get_user("bob")

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

  test "websocket_info added_as_contact returns payload" do
    state = %{user: "alice"}

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_info({:added_as_contact, "bob"}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "added_as_contact"
    assert data["contact"] == "bob"
  end

  test "websocket_info message_deleted returns payload" do
    state = %{user: "alice"}

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_info({:message_deleted, "alice:bob", 10}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "message_deleted"
    assert data["chat_id"] == "alice:bob"
    assert data["message_id"] == 10
  end

  test "websocket_info websocket_message passthrough" do
    state = %{user: "alice"}
    payload = "{\"ping\":true}"

    assert {:reply, {:text, ^payload}, ^state} =
             SocketHandler.websocket_info({:websocket_message, payload}, state)
  end

  test "terminate marks user offline" do
    ChatApp.ActivityServer.user_online("alice")

    assert :ok = SocketHandler.terminate(:normal, nil, %{user: "alice"})
    assert ChatApp.ActivityServer.is_online?("alice") == false
  end

  test "websocket_init registers user and flushes pending" do
    ChatApp.ActivityServer.add_pending("alice", {:new_chatroom, "room1"})

    assert {:ok, %{user: "alice"}} = SocketHandler.websocket_init(%{user: "alice"})
    assert Registry.lookup(ChatApp.UsersRegistry, "alice") != []
    assert_receive {:initial_notifications, notifications}
    assert length(notifications) == 1

    assert match?(
             [
               %{
                 type: "new_chatroom",
                 chat_id: "room1",
                 id: _,
                 timestamp: _
               }
             ],
             notifications
           )
  end

  test "websocket_handle ignores non-text frames" do
    state = %{user: "alice"}
    assert {:ok, ^state} = SocketHandler.websocket_handle({:binary, "x"}, state)
  end

  test "websocket_handle returns controlled error for invalid json" do
    state = %{user: "alice"}

    assert {:reply, {:text, reply}, ^state} =
             SocketHandler.websocket_handle({:text, "{invalid_json"}, state)

    data = Jason.decode!(reply)
    assert data["status"] == "error"
    assert data["error"] == "invalid_json"
  end
end
