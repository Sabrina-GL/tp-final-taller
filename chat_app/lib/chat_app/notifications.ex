defmodule ChatApp.Notifications do
  def notify_new_chatroom(user, chat_id) do
    case Registry.lookup(ChatApp.UsersRegistry, user) do
      [{pid, _}] ->
        send(pid, {:new_chatroom, chat_id})

      [] ->
        :offline
    end
  end
end
