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

  def notify_new_contact(user, who_added) do
    notification = {:added_as_contact, who_added}
    notify_user(user, notification)
  end

  def get_pending_notifications(user) do
    ensure_activity_server(user)

    ActivityServer.consume_pending(user)
    |> format_pending_notifications()
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

  defp format_pending_notifications(pending) do
    Enum.map(pending, fn notification ->
      case notification do
        {:new_message, chat_id, message} ->
          %{
            id: System.unique_integer([:positive]),
            type: "new_message",
            chat_id: chat_id,
            from: message.from,
            content: message.msg_content,
            timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
          }

        {:new_chatroom, chat_id} ->
          %{
            id: System.unique_integer([:positive]),
            type: "new_chatroom",
            chat_id: chat_id,
            timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
          }

        {:added_as_contact, contact} ->
          %{
            id: System.unique_integer([:positive]),
            type: "added_as_contact",
            from: contact,
            timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
          }
      end
    end)
  end
end
