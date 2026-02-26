defmodule ChatWeb.SocketHandler do
  @moduledoc """
  Módulo que maneja las conexiones WebSocket utilizando Cowboy.

  Este módulo implementa el comportamiento :cowboy_websocket y gestiona:
  - Conexiones de usuarios (online/offline)
  - Envío y recepción de mensajes en tiempo real
  - Gestión de contactos (agregar, bloquear, eliminar)
  - Notificaciones en tiempo real
  """
  @behaviour :cowboy_websocket
  alias ChatApp.{
    ActivitySupervisor,
    ActivityServer,
    Accounts,
    ChatManager,
    ChatRoomServer,
    Notifications
  }

  # ======== Callbacks de Cowboy WebSocket ==========
  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    IO.puts("Cliente conectado: #{state.user}")
    Registry.register(ChatApp.UsersRegistry, state.user, self())
    ActivitySupervisor.start_activity_server(state.user)
    ActivityServer.user_online(state.user)

    notifications = Notifications.get_pending_notifications(state.user)

    if notifications != [] do
      send(self(), {:initial_notifications, notifications})
    end

    {:ok, state}
  end

  def websocket_handle({:text, msg}, state) do
    reply =
      case Jason.decode(msg) do
        {:ok, data} -> handle_action(data, state)
        {:error, _} -> %{status: :error, error: :invalid_json}
      end

    {:reply, {:text, Jason.encode!(reply)}, state}
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  def terminate(_reason, _request, state) do
    ChatApp.ActivityServer.user_offline(state.user)
    :ok
  end

  # ======== Websocket info handlers (notificaciones) ==========
  def websocket_info({:new_chatroom, chat_id}, state) do
    reply = Jason.encode!(%{type: :new_chatroom, chat_id: chat_id})
    {:reply, {:text, reply}, state}
  end

  def websocket_info({:new_message, chat_id, message}, state) do
    reply = Jason.encode!(%{status: :new_message, chat_id: chat_id, message: message})
    {:reply, {:text, reply}, state}
  end

  def websocket_info({:added_as_contact, contact}, state) do
    reply = Jason.encode!(%{status: :added_as_contact, contact: contact})
    {:reply, {:text, reply}, state}
  end

  def websocket_info({:initial_notifications, notifications}, state) do
    {:reply,
     {:text, Jason.encode!(%{type: "initial_notifications", notifications: notifications})},
     state}
  end

  def websocket_info({:message_deleted, chat_id, message_id}, state) do
    reply =
      Jason.encode!(%{
        status: "message_deleted",
        chat_id: chat_id,
        message_id: message_id
      })

    {:reply, {:text, reply}, state}
  end

  def websocket_info({:websocket_message, message}, state) do
    {:reply, {:text, message}, state}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  # ========== Action handlers ==========
  defp handle_action(%{"action" => "get_contacts"} = _data, state) do
    case Accounts.get_contacts(state.user) do
      {:ok, contacts} ->
        %{contacts: format_contacts_with_status(state.user, contacts)}

      {:error, reason} ->
        %{error: reason}
    end
  end

  defp handle_action(%{"action" => "get_blocked_contacts"} = _data, state) do
    case Accounts.get_blocked_contacts(state.user) do
      {:ok, contacts} -> %{blocked_contacts: contacts}
      {:error, reason} -> %{error: reason}
    end
  end

  defp handle_action(%{"action" => "get_chatrooms"} = _data, state) do
    case ChatManager.get_user_chatrooms(state.user) do
      {:error, reason} -> %{error: reason}
      chatrooms -> %{chatrooms: chatrooms}
    end
  end

  defp handle_action(%{"action" => "get_messages"} = data, _state) do
    {:ok, messages} = ChatRoomServer.get_messages(data["chat_id"])
    %{messages: messages}
  end

  defp handle_action(%{"action" => "get_status"} = data, state) do
    user = data["user"] || state.user
    blocked = user != state.user and Accounts.interaction_blocked?(state.user, user)

    if blocked do
      %{user: user, online: false, last_seen: nil}
    else
    online? = ActivityServer.is_online?(user)

    # last_seen returns {:ok, timestamp} or {:error, reason}
    last_seen_value =
      case ActivityServer.last_seen(user) do
        %DateTime{} = dt -> DateTime.to_unix(dt)
        ts when is_integer(ts) -> ts
        _ -> nil
      end

    %{user: user, online: online?, last_seen: last_seen_value}
    end
  end

  defp handle_action(%{"action" => "add_contact"} = data, state) do
    with :ok <- Accounts.add_contact(state.user, data["contact"]),
         {:ok, contacts} <- Accounts.get_contacts(state.user),
         {:ok, _chat_id} <-
           ChatManager.create_private_chat(state.user, data["contact"]),
         chatrooms <- ChatManager.get_user_chatrooms(state.user) do
      %{
        status: :contact_added,
        contacts: format_contacts_with_status(state.user, contacts),
        chatrooms: chatrooms,
        chat_opened: true,
        chat_id: "#{Enum.sort([state.user, data["contact"]]) |> Enum.join(":")}"
      }
    else
      {:error, reason} -> %{error: reason}
    end
  end

  defp handle_action(%{"action" => "block_contact"} = data, state) do
    case Accounts.block_contact(state.user, data["contact"]) do
      :ok ->
        case Accounts.get_contacts(state.user) do
          {:ok, contacts} ->
            %{
              status: :contact_blocked,
              contact: data["contact"],
              contacts: format_contacts_with_status(state.user, contacts)
            }

          {:error, _} ->
            %{status: :contact_blocked, contact: data["contact"]}
        end

      {:error, reason} ->
        %{error: reason}
    end
  end

  defp handle_action(%{"action" => "unblock_contact"} = data, state) do
    case Accounts.unblock_contact(state.user, data["contact"]) do
      :ok ->
        case Accounts.get_blocked_contacts(state.user) do
          {:ok, contacts} ->
            %{
              status: :contact_unblocked,
              contact: data["contact"],
              blocked_contacts: contacts
            }

          {:error, _} ->
            %{status: :contact_unblocked, contact: data["contact"]}
        end

      {:error, reason} ->
        %{error: reason}
    end
  end

  defp handle_action(%{"action" => "delete_contact"} = data, state) do
    case Accounts.delete_contact(state.user, data["contact"]) do
      :ok ->
        case Accounts.get_contacts(state.user) do
          {:ok, contacts} ->
            %{
              status: :contact_deleted,
              contact: data["contact"],
              contacts: format_contacts_with_status(state.user, contacts)
            }

          {:error, _} ->
            %{status: :contact_deleted, contact: data["contact"]}
        end

      {:error, reason} ->
        %{error: reason}
    end
  end

  defp handle_action(%{"action" => "create_group_chat"} = data, state) do
    with {:ok, chat_id} <-
           ChatManager.create_group_chat(
             state.user,
             data["group_name"],
             data["participants"]
           ) do
      %{
        status: :group_chat_created,
        chat_id: chat_id,
        group_name: data["group_name"]
      }
    else
      {:error, reason} -> %{error: reason}
    end
  end

  defp handle_action(%{"action" => "send_message"} = data, state) do
    case ChatRoomServer.add_message(data["chat_id"], state.user, data["msg_content"]) do
      {:error, reason} ->
        %{status: :error, error: reason}

      message ->
        %{status: :ok, message: message}
    end
  end

  defp handle_action(%{"action" => "send_file"} = data, state) do
    # Validate required fields
    with {:ok, file_content} <- validate_field(data, "file_content"),
         {:ok, file_name} <- validate_field(data, "file_name"),
         {:ok, file_type} <- validate_field(data, "file_type"),
         {:ok, chat_id} <- validate_field(data, "chat_id") do
      file_data = %{
        base64_content: file_content,
        filename: file_name,
        mime_type: file_type
      }

      case ChatRoomServer.add_message(chat_id, state.user, nil, file_data: file_data) do
        {:error, reason} ->
          %{status: :error, error: reason}

        message ->
          %{status: :ok, message: message, type: :file}
      end
    else
      {:error, field} -> %{status: :error, error: "Missing required field: #{field}"}
    end
  end

  defp handle_action(%{"action" => "search_messages"} = data, _state) do
    case ChatRoomServer.search_messages(data["chat_id"], data["query"]) do
      {:error, reason} ->
        %{status: :error, error: reason}

      messages ->
        %{
          search_results: messages,
          query: data["query"]
        }
    end
  end

  defp handle_action(%{"action" => "delete_message"} = data, state) do
    case ChatRoomServer.delete_message(data["chat_id"], state.user, data["message_id"]) do
      :ok -> %{status: :message_deleted, message_id: data["message_id"]}
      {:error, reason} -> %{status: :error, error: reason}
    end
  end

  defp handle_action(%{"action" => "delete_messages"} = data, state) do
    case ChatRoomServer.delete_messages(
           data["chat_id"],
           state.user,
           data["message_ids"] || []
         ) do
      {:ok, deleted_count} -> %{status: :messages_deleted, deleted_count: deleted_count}
      {:error, reason} -> %{status: :error, error: reason}
    end
  end

  defp handle_action(%{"action" => _} = _data, _state) do
    %{error: :unknown_action}
  end

  # ========== Helpers ==========
  defp validate_field(data, field_name) do
    case Map.get(data, field_name) do
      nil -> {:error, field_name}
      "" -> {:error, field_name}
      value -> {:ok, value}
    end
  end

  defp format_contacts_with_status(requester, contacts) do
    Enum.map(contacts, fn contact ->
      online =
        if Accounts.interaction_blocked?(requester, contact) do
          false
        else
          ChatApp.ActivityServer.is_online?(contact)
        end

      %{username: contact, online: online}
    end)
  end
end
