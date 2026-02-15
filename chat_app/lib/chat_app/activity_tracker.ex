defmodule ChatApp.ActivityTracker do
  use GenServer

  # Client API
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def user_online(username) do
    GenServer.call(__MODULE__, {:user_online, username})
  end

  def user_offline(username) do
    GenServer.call(__MODULE__, {:user_offline, username})
  end

  def is_online?(username) do
    GenServer.call(__MODULE__, {:is_online, username})
  end

  def last_seen(username) do
    GenServer.call(__MODULE__, {:last_seen, username})
  end

  def add_pending(username, notification) do
    GenServer.call(__MODULE__, {:add_pending, username, notification})
  end

  def consume_pending(username) do
    GenServer.call(__MODULE__, {:consume_pending, username})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:user_online, username}, _from, state) do
    now = DateTime.utc_now()
    entry = Map.get(state, username, %{status: :offline, last_seen: nil, pending: []})
    updated = %{entry | status: :online, last_seen: now}
    {:reply, :ok, Map.put(state, username, updated)}
  end

  def handle_call({:user_offline, username}, _from, state) do
    now = DateTime.utc_now()
    entry = Map.get(state, username, %{status: :offline, last_seen: nil, pending: []})
    updated = %{entry | status: :offline, last_seen: now}
    {:reply, :ok, Map.put(state, username, updated)}
  end

  def handle_call({:is_online, username}, _from, state) do
    online? =
      case Map.get(state, username) do
        %{status: :online} -> true
        _ -> false
      end

    {:reply, online?, state}
  end

  def handle_call({:last_seen, username}, _from, state) do
    case Map.get(state, username) do
      nil -> {:reply, {:error, :user_not_found}, state}
      %{last_seen: last_seen} -> {:reply, {:ok, last_seen}, state}
    end
  end

  def handle_call({:add_pending, username, notification}, _from, state) do
    entry = Map.get(state, username, %{status: :offline, last_seen: nil, pending: []})
    updated = %{entry | pending: entry.pending ++ [notification]}
    {:reply, :ok, Map.put(state, username, updated)}
  end

  def handle_call({:consume_pending, username}, _from, state) do
    entry = Map.get(state, username, %{status: :offline, last_seen: nil, pending: []})
    pending = entry.pending
    updated = %{entry | pending: []}
    {:reply, pending, Map.put(state, username, updated)}
  end
end
