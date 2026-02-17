defmodule ChatApp.Notifications do
  def notify_new_chatroom(user, chat_id) do
    notification = {:new_chatroom, chat_id}
    notify_user(user, notification)
  end

  def notify_new_message(user, chat_id, message) do
    notification = {:new_message, chat_id, message}
    notify_user(user, notification)
  end

  defp notify_user(user, notification) do
    case Registry.lookup(ChatApp.UsersRegistry, user) do
      [{pid, _}] ->
        send(pid, notification)
        :ok

      [] ->
        case Registry.lookup(ChatApp.ActivityRegistry, user) do
          [{pid, _}] ->
            if ChatApp.ActivityServer.is_online?(user) do
              send(pid, notification)
              :ok
            else
              ChatApp.ActivityServer.add_pending(user, notification)
              :offline
            end

          [] ->
            # Si no hay ActivityServer, arrancarlo y luego agregar pendiente
            {:ok, _pid} = ChatApp.ActivityServer.start_link(user)
            ChatApp.ActivityServer.add_pending(user, notification)
            :offline
        end
    end
  end
end
