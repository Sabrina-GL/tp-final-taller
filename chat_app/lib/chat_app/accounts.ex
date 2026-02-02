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
end
