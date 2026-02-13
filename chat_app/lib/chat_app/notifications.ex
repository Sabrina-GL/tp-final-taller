defmodule ChatApp.Notifications do
  def notify_new_chatroom(user, chat_id) do
    case Registry.lookup(ChatApp.UsersRegistry, user) do
      [{pid, _}] ->
        send(pid, {:new_chatroom, chat_id})

      [] ->
        :offline
    end
  end

  def notify_new_message(user, chat_id, message) do
    case Registry.lookup(ChatApp.UsersRegistry, user) do
      [{pid, _}] ->
        send(pid, {:new_message, chat_id, message})

      [] ->
        :offline
    end
  end
end
