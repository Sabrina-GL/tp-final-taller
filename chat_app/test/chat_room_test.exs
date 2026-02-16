defmodule ChatApp.ChatRoomTest do
  use ExUnit.Case
  alias ChatApp.{ChatRoom, Accounts}

  setup do
    # Clear database before each test
    ChatApp.Repo.delete_all(ChatApp.Schemas.User)
    ChatApp.Repo.delete_all(ChatApp.Schemas.Message)

    # Clear in-memory metadata for accounts
    case :ets.whereis(:accounts_metadata) do
      :undefined -> :ok
      tid -> :ets.delete_all_objects(tid)
    end

    Accounts.register_user("alice", "password")
    Accounts.register_user("bob", "password")

    # Limpiar el registro de chat rooms antes de cada prueba
    Registry.select(ChatApp.ChatRoomsRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$2"]}])
    |> Enum.each(&Process.exit(&1, :kill))

    Registry.unregister_match(ChatApp.ChatRoomsRegistry, :_, :_)

    chat_id = "alice:bob:#{System.unique_integer([:positive])}"

    {:ok, _pid} =
      ChatApp.ChatRoom.start_link(%{
        chat_id: chat_id,
        type: :private,
        participants: ["alice", "bob"],
        messages: []
      })

    %{chat_id: chat_id}
  end

  describe "add_message" do
    test "no permite agregar mensajes de usuarios que no son participantes", %{chat_id: chat_id} do
      {:error, reason} = ChatRoom.add_message(chat_id, "charlie", "Hola a todos")
      assert reason == :not_participant
    end

    test "agrega un mensaje al chat room", %{chat_id: chat_id} do
      msg = ChatRoom.add_message(chat_id, "alice", "Hola Bob")
      {:ok, messages} = ChatRoom.get_messages(chat_id)

      assert msg.from == "alice"
      assert msg.msg_content == "Hola Bob"
      assert msg.timestamp != nil
      assert length(messages) == 1
    end

    test "mantiene solo los últimos 10 mensajes", %{chat_id: chat_id} do
      for i <- 1..12 do
        ChatRoom.add_message(chat_id, "alice", "Mensaje #{i}")
      end

      {:ok, messages} = ChatRoom.get_messages(chat_id)
      assert length(messages) == 10
      assert Enum.at(messages, -1).msg_content == "Mensaje 3"
      assert Enum.at(messages, 0).msg_content == "Mensaje 12"
    end
  end

  describe "get_messages" do
    test "devuelve una lista vacía si no hay mensajes", %{chat_id: chat_id} do
      {:ok, messages} = ChatRoom.get_messages(chat_id)
      assert messages == []
    end

    test "devuelve los mensajes en orden inverso al agregado", %{chat_id: chat_id} do
      ChatRoom.add_message(chat_id, "alice", "Primer mensaje")
      ChatRoom.add_message(chat_id, "bob", "Segundo mensaje")

      {:ok, messages} = ChatRoom.get_messages(chat_id)

      assert length(messages) == 2
      assert Enum.at(messages, 0).msg_content == "Segundo mensaje"
      assert Enum.at(messages, 1).msg_content == "Primer mensaje"
    end
  end

  describe "search_messages" do
    test "search_messages devuelve solo los mensajes que contienen la palabra clave", %{
      chat_id: chat_id
    } do
      ChatRoom.add_message(chat_id, "alice", "hola juan")
      ChatRoom.add_message(chat_id, "bob", "chau ana")
      ChatRoom.add_message(chat_id, "alice", "hola de nuevo")

      results = ChatRoom.search_messages(chat_id, "hola")
      assert length(results) == 2
    end

    test "search_messages devuelve una lista vacía si no hay coincidencias", %{chat_id: chat_id} do
      ChatRoom.add_message(chat_id, "alice", "hola juan")
      ChatRoom.add_message(chat_id, "bob", "chau ana")

      results = ChatRoom.search_messages(chat_id, "adios")
      assert results == []
    end

    test "search_messages es case-insensitive", %{chat_id: chat_id} do
      ChatRoom.add_message(chat_id, "alice", "Hola Juan")
      ChatRoom.add_message(chat_id, "bob", "chau ana")

      results = ChatRoom.search_messages(chat_id, "hola")
      assert length(results) == 1

      results = ChatRoom.search_messages(chat_id, "HOLA")
      assert length(results) == 1
    end
  end
end
