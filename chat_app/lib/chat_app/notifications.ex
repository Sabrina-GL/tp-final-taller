defmodule ChatApp.Notifications do
  def notify_new_chatroom(user, chat_id) do
    notification = {:new_chatroom, chat_id}

    case Registry.lookup(ChatApp.UsersRegistry, user) do
      [{pid, _}] ->
        send(pid, notification)
        :ok

      [] ->
        ChatApp.ActivityTracker.add_pending(user, notification)
        :offline
    end
  end

  def notify_new_message(user, chat_id, message) do
    notification = {:new_message, chat_id, message}

    case Registry.lookup(ChatApp.UsersRegistry, user) do
      [{pid, _}] ->
        send(pid, notification)
        :ok

      [] ->
        ChatApp.ActivityTracker.add_pending(user, notification)
        :offline
    end
  end
end
