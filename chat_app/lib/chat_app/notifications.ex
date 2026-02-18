defmodule ChatApp.Notifications do
  alias ChatApp.{ActivityServer, ActivitySupervisor}

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
        ensure_activity_server(user)
        ActivityServer.add_pending(user, notification)
        :offline
    end
  end

  defp ensure_activity_server(user) do
    case Registry.lookup(ChatApp.ActivityRegistry, user) do
      [{_pid, _}] ->
        :ok

      [] ->
        case ActivitySupervisor.start_activity_server(user) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          _ -> :ok
        end
    end
  end
end
