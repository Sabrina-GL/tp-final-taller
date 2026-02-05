defmodule ChatApp.Accounts do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    table = :ets.new(:accounts, [:set, :public, :named_table])
    {:ok, table}
  end

  def register_user(username, password) do
    GenServer.call(__MODULE__, {:register_user, username, password})
  end

  def authenticate_user(username, password) do
    GenServer.call(__MODULE__, {:authenticate_user, username, password})
  end

  def get_contacts(username) do
    GenServer.call(__MODULE__, {:get_contacts, username})
  end

  def add_contact(username, contact) do
    GenServer.call(__MODULE__, {:add_contact, username, contact})
  end

  # SERVER

  def handle_call({:register_user, username, password}, _from, table) do
    case :ets.lookup(table, username) do
      [] ->
        user = %{
          username: username,
          password: password,
          contacts: MapSet.new(),
          chat_rooms: MapSet.new()
        }

        :ets.insert(table, {username, user})
        {:reply, :ok, table}

      _ ->
        {:reply, {:error, :user_exists}, table}
    end
  end

  def handle_call({:authenticate_user, username, password}, _from, table) do
    case :ets.lookup(table, username) do
      [{^username, user}] when user.password == password ->
        {:reply, :ok, table}

      _ ->
        {:reply, {:error, :invalid_credentials}, table}
    end
  end

  def handle_call({:get_contacts, username}, _from, table) do
    case :ets.lookup(table, username) do
      [{^username, user}] ->
        {:reply, {:ok, MapSet.to_list(user.contacts)}, table}

      _ ->
        {:reply, {:error, :user_not_found}, table}
    end
  end

  def handle_call({:add_contact, username, contact}, _from, table) do
    cond do
      username == contact ->
        {:reply, {:error, :cannot_add_self}, table}

      :ets.lookup(table, contact) == [] ->
        {:reply, {:error, :contact_not_found}, table}

      true ->
        case :ets.lookup(table, username) do
          [{^username, user}] ->
            updated_user = %{user | contacts: MapSet.put(user.contacts, contact)}
            :ets.insert(table, {username, updated_user})
            {:reply, :ok, table}

          _ ->
            {:reply, {:error, :user_not_found}, table}
        end
    end
  end
end
