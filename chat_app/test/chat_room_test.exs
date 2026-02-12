defmodule ChatApp.ChatRoomTest do
  use ExUnit.Case

  test "search_messages devuelve solo los mensajes que contienen la palabra clave" do
    {:ok, pid} =
      ChatApp.ChatRoom.start_link(%{
        id: "chat-test",
        participants: ["ana", "juan"],
        messages: []
      })

    ChatApp.ChatRoom.add_message(pid, "ana", "hola juan")
    ChatApp.ChatRoom.add_message(pid, "juan", "chau ana")
    ChatApp.ChatRoom.add_message(pid, "ana", "hola de nuevo")

    results = ChatApp.ChatRoom.search_messages(pid, "hola")

    assert length(results) == 2
  end
end
