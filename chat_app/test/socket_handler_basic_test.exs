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
end
