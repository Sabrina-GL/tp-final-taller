defmodule ChatApp.ChatRoomTest do
  use ChatApp.DataCase, async: false
  alias ChatApp.{ChatRoomServer, Accounts}

  setup do
    create_test_users(["alice", "bob", "charlie"])
    start_activity_servers(["alice", "bob", "charlie"])

    {:ok, chat_id} = ChatApp.ChatManager.create_private_chat("alice", "bob")
    %{chat_id: chat_id}
  end

  describe "add_message" do
    test "no permite agregar mensajes de usuarios que no son participantes", %{chat_id: chat_id} do
      {:error, reason} = ChatRoomServer.add_message(chat_id, "charlie", "Hola a todos")
      assert reason == :not_participant
    end

    test "agrega un mensaje al chat room", %{chat_id: chat_id} do
      msg = ChatRoomServer.add_message(chat_id, "alice", "Hola Bob")
      {:ok, messages} = ChatRoomServer.get_messages(chat_id)

      assert msg.from == "alice"
      assert msg.msg_content == "Hola Bob"
      assert msg.timestamp != nil
      assert length(messages) == 1
    end

    test "mantiene solo los últimos 10 mensajes", %{chat_id: chat_id} do
      for i <- 1..12 do
        ChatRoomServer.add_message(chat_id, "alice", "Mensaje #{i}")
      end

      {:ok, messages} = ChatRoomServer.get_messages(chat_id)
      assert length(messages) == 10
      assert Enum.at(messages, -1).msg_content == "Mensaje 3"
      assert Enum.at(messages, 0).msg_content == "Mensaje 12"
    end

    test "bloqueo impide enviar mensajes", %{chat_id: chat_id} do
      assert :ok = Accounts.block_contact("bob", "alice")
      assert {:error, :contact_blocked} = ChatRoomServer.add_message(chat_id, "alice", "Hola")
    end
  end

  describe "get_messages" do
    test "devuelve una lista vacía si no hay mensajes", %{chat_id: chat_id} do
      {:ok, messages} = ChatRoomServer.get_messages(chat_id)
      assert messages == []
    end

    test "devuelve los mensajes en orden inverso al agregado", %{chat_id: chat_id} do
      ChatRoomServer.add_message(chat_id, "alice", "Primer mensaje")
      ChatRoomServer.add_message(chat_id, "bob", "Segundo mensaje")

      {:ok, messages} = ChatRoomServer.get_messages(chat_id)

      assert length(messages) == 2
      assert Enum.at(messages, 0).msg_content == "Segundo mensaje"
      assert Enum.at(messages, 1).msg_content == "Primer mensaje"
    end
  end

  describe "get_room_state" do
    test "devuelve el estado actual del chat room", %{chat_id: chat_id} do
      ChatRoomServer.add_message(chat_id, "alice", "Hola Bob")
      ChatRoomServer.add_message(chat_id, "bob", "Hola Alice")

      {:ok, state} = ChatRoomServer.get_room_state(chat_id)

      assert state.chat_id == chat_id
      assert state.type == :private
      assert Enum.sort(state.participants) == ["alice", "bob"]
      assert length(state.messages) == 2
    end
  end

  describe "search_messages" do
    test "search_messages devuelve solo los mensajes que contienen la palabra clave", %{
      chat_id: chat_id
    } do
      ChatRoomServer.add_message(chat_id, "alice", "hola juan")
      ChatRoomServer.add_message(chat_id, "bob", "chau ana")
      ChatRoomServer.add_message(chat_id, "alice", "hola de nuevo")

      results = ChatRoomServer.search_messages(chat_id, "hola")
      assert length(results) == 2
    end

    test "search_messages devuelve una lista vacía si no hay coincidencias", %{chat_id: chat_id} do
      ChatRoomServer.add_message(chat_id, "alice", "hola juan")
      ChatRoomServer.add_message(chat_id, "bob", "chau ana")

      results = ChatRoomServer.search_messages(chat_id, "adios")
      assert results == []
    end

    test "search_messages es case-insensitive", %{chat_id: chat_id} do
      ChatRoomServer.add_message(chat_id, "alice", "Hola Juan")
      ChatRoomServer.add_message(chat_id, "bob", "chau ana")

      results = ChatRoomServer.search_messages(chat_id, "hola")
      assert length(results) == 1

      results = ChatRoomServer.search_messages(chat_id, "HOLA")
      assert length(results) == 1
    end
  end

  describe "delete_messages" do
    test "delete_message borra un mensaje por id", %{chat_id: chat_id} do
      msg = ChatRoomServer.add_message(chat_id, "alice", "Mensaje a borrar")
      assert is_integer(msg.id)

      assert :ok = ChatRoomServer.delete_message(chat_id, "alice", msg.id)
      {:ok, messages} = ChatRoomServer.get_messages(chat_id)
      assert Enum.empty?(messages)
    end

    test "delete_messages borra múltiples mensajes", %{chat_id: chat_id} do
      msg1 = ChatRoomServer.add_message(chat_id, "alice", "M1")
      msg2 = ChatRoomServer.add_message(chat_id, "bob", "M2")
      _msg3 = ChatRoomServer.add_message(chat_id, "alice", "M3")

      assert {:ok, 2} = ChatRoomServer.delete_messages(chat_id, "alice", [msg1.id, msg2.id])

      {:ok, messages} = ChatRoomServer.get_messages(chat_id)
      assert length(messages) == 1
      assert hd(messages).msg_content == "M3"
    end

    test "delete_message falla si requester no es participante", %{chat_id: chat_id} do
      msg = ChatRoomServer.add_message(chat_id, "alice", "Mensaje")

      assert {:error, :not_participant} =
               ChatRoomServer.delete_message(chat_id, "charlie", msg.id)
    end

    test "delete_message falla si mensaje no existe", %{chat_id: chat_id} do
      assert {:error, :message_not_found} = ChatRoomServer.delete_message(chat_id, "alice", 9999)
    end

    test "delete_messages retorna 0 si no hay mensajes para borrar", %{chat_id: chat_id} do
      _msg = ChatRoomServer.add_message(chat_id, "alice", "M1")
      assert {:ok, 0} = ChatRoomServer.delete_messages(chat_id, "bob", [9999, 8888])
    end

    test "delete_messages falla si requester no es participante", %{chat_id: chat_id} do
      msg = ChatRoomServer.add_message(chat_id, "alice", "Mensaje")

      assert {:error, :not_participant} =
               ChatRoomServer.delete_messages(chat_id, "charlie", [msg.id])
    end
  end

  describe "file attachments" do
    test "add_message con file_data guarda metadata de archivo", %{chat_id: chat_id} do
      file_data = %{
        base64_content: Base.encode64("contenido adjunto"),
        filename: "adjunto.txt",
        mime_type: "text/plain"
      }

      msg = ChatRoomServer.add_message(chat_id, "alice", nil, file_data: file_data)

      assert msg.from == "alice"
      assert msg.msg_content == "[File: adjunto.txt]"
      assert msg.file_name == "adjunto.txt"
      assert msg.file_type == "text/plain"
      assert is_integer(msg.file_size)
      assert is_binary(msg.file_path)

      assert :ok = ChatApp.FileManager.delete_file(msg.file_path)
    end

    test "add_message con file_data inválido retorna error", %{chat_id: chat_id} do
      file_data = %{
        base64_content: "***invalid***",
        filename: "mal.txt",
        mime_type: "text/plain"
      }

      assert {:error, reason} =
               ChatRoomServer.add_message(chat_id, "alice", nil, file_data: file_data)

      assert String.contains?(reason, "Invalid base64 encoding")
    end

    test "delete_message elimina archivo físico asociado", %{chat_id: chat_id} do
      file_data = %{
        base64_content: Base.encode64("se elimina"),
        filename: "delete_file.txt",
        mime_type: "text/plain"
      }

      msg = ChatRoomServer.add_message(chat_id, "alice", nil, file_data: file_data)
      full_path = ChatApp.FileManager.get_file_path(msg.file_path)
      assert File.exists?(full_path)

      assert :ok = ChatRoomServer.delete_message(chat_id, "alice", msg.id)
      refute File.exists?(full_path)
    end
  end
end
