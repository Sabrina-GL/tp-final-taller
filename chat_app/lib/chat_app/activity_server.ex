defmodule ChatApp.ActivityServer do
  @moduledoc """
  Gestiona el estado de actividad de cada usuario, incluyendo su estado en línea, última conexión y notificaciones pendientes.

  Este GenServer se inicia para cada usuario conectado y mantiene:
  - El estado actual del usuario (online/offline)
  - La última vez que estuvo en línea
  - Cola de notificaciones pendientes (nuevos mensajes, cambios de estado de contactos, etc.)

  Las notificaciones pendientes se entregan cuando el usuario se conecta, y los cambios de estado se notifican a los contactos en tiempo real.
  """
  use GenServer

  # ========= Client API ==========
  def start_link(username) do
    GenServer.start_link(__MODULE__, username, name: via_tuple(username))
  end

  defp via_tuple(username) do
    {:via, Registry, {ChatApp.ActivityRegistry, username}}
  end

  def user_online(username) do
    GenServer.call(via_tuple(username), :user_online)
  end

  def user_offline(username) do
    GenServer.call(via_tuple(username), :user_offline)
  end

  def is_online?(username) do
    case Registry.lookup(ChatApp.ActivityRegistry, username) do
      [{_pid, _}] ->
        GenServer.call(via_tuple(username), :is_online)

      [] ->
        false
    end
  end

  def last_seen(username) do
    GenServer.call(via_tuple(username), :last_seen)
  end

  def add_pending(username, notification) do
    GenServer.call(via_tuple(username), {:add_pending, notification})
  end

  def consume_pending(username) do
    GenServer.call(via_tuple(username), :consume_pending)
  end

  # ========= GenServer Callbacks ==========
  def init(username) do
    {:ok, %{username: username, status: :offline, last_seen: nil, pending: []}}
  end

  def handle_call(:user_online, _from, state) do
    new_state = %{state | status: :online, last_seen: DateTime.utc_now()}
    notify_contacts_online(state.username, true)
    {:reply, :ok, new_state}
  end

  def handle_call(:user_offline, _from, state) do
    new_state = %{state | status: :offline, last_seen: DateTime.utc_now()}
    notify_contacts_online(state.username, false)
    {:reply, :ok, new_state}
  end

  def handle_call(:is_online, _from, state) do
    {:reply, state.status == :online, state}
  end

  def handle_call(:last_seen, _from, state) do
    {:reply, state.last_seen, state}
  end

  def handle_call({:add_pending, notification}, _from, state) do
    {:reply, :ok, %{state | pending: [notification | state.pending]}}
  end

  def handle_call(:consume_pending, _from, state) do
    {:reply, Enum.reverse(state.pending), %{state | pending: []}}
  end

  def handle_info({:new_chatroom, _chat_id} = msg, state) do
    {:noreply, %{state | pending: state.pending ++ [msg]}}
  end

  def handle_info({:new_message, _chat_id, _message} = msg, state) do
    {:noreply, %{state | pending: state.pending ++ [msg]}}
  end

  def handle_info({:contact_status_change, username, online}, state) do
    send_to_websocket(state.username, %{
      type: "contact_status",
      username: username,
      online: online
    })

    {:noreply, state}
  end

  def handle_info(msg, state) do
    IO.puts("ActivityServer received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  # ========== Helpers ==========
  defp notify_contacts_online(username, online) do
    case ChatApp.Accounts.get_contacts_who_added_user(username) do
      {:ok, contacts} ->
        online_contacts = Enum.filter(contacts, &is_online?/1)

        for contact <- online_contacts do
          case Registry.lookup(ChatApp.ActivityRegistry, contact) do
            [{pid, _}] ->
              Process.send(pid, {:contact_status_change, username, online}, [])

            [] ->
              :ok
          end
        end

      _ ->
        :ok
    end
  end

  defp send_to_websocket(username, message) do
    case Registry.lookup(ChatApp.UsersRegistry, username) do
      [{pid, _}] ->
        Process.send(pid, {:websocket_message, Jason.encode!(message)}, [])

      [] ->
        :ok
    end
  end
end
