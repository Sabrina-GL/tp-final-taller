defmodule ChatApp.Accounts do
  use GenServer

  alias ChatApp.Repo
  alias ChatApp.Schemas.User

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    # Initialize in-memory storage for contacts and chat_rooms
    table = :ets.new(:accounts_metadata, [:set, :public, :named_table])
    {:ok, table}
  end

  def register_user(username, password) do
    GenServer.call(__MODULE__, {:register_user, username, password})
  end

  def authenticate_user(username, password) do
    GenServer.call(__MODULE__, {:authenticate_user, username, password})
  end

  def get_user(username) do
    GenServer.call(__MODULE__, {:get_user, username})
  end

  def get_contacts(username) do
    GenServer.call(__MODULE__, {:get_contacts, username})
  end

  def add_contact(username, contact) do
    GenServer.call(__MODULE__, {:add_contact, username, contact})
  end

  def get_chatrooms(username) do
    GenServer.call(__MODULE__, {:get_chatrooms, username})
  end

  def add_chatroom(username, chatroom_id) do
    GenServer.call(__MODULE__, {:add_chatroom, username, chatroom_id})
  end

  def update_last_seen(username) do
    GenServer.call(__MODULE__, {:update_last_seen, username})
  end

  # SERVER

  def handle_call({:register_user, username, password}, _from, table) do
    reply =
      cond do
        not is_binary(username) or String.trim(username) == "" ->
          {:error, :invalid_username}

        String.length(username) < 3 ->
          {:error, :username_too_short}

        not is_binary(password) or String.length(password) < 6 ->
          {:error, :password_too_short}

        true ->
          # Check if user already exists in database
          case Repo.get_by(User, username: username) do
            nil ->
              hashed = Bcrypt.hash_pwd_salt(password)
              now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

              changeset =
                User.changeset(%User{}, %{
                  username: username,
                  password_hash: hashed,
                  last_seen: now
                })

              case Repo.insert(changeset) do
                {:ok, _user} ->
                  # Initialize in-memory metadata
                  user_key = String.to_atom("#{username}_metadata")
                  :ets.insert(table, {user_key, %{contacts: MapSet.new(), chat_rooms: MapSet.new()}})
                  :ok

                {:error, _changeset} ->
                  {:error, :registration_failed}
              end

            _user ->
              {:error, :user_exists}
          end
      end

    {:reply, reply, table}
  end

  def handle_call({:authenticate_user, username, password}, _from, table) do
    reply =
      case Repo.get_by(User, username: username) do
        nil ->
          {:error, :invalid_credentials}

        user ->
          if Bcrypt.verify_pass(password, user.password_hash) do
            # Update last_seen timestamp (truncate microseconds)
            now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
            User.update_last_seen(user, now)
            |> Repo.update()

            :ok
          else
            {:error, :invalid_credentials}
          end
      end

    {:reply, reply, table}
  end

  def handle_call({:get_user, username}, _from, table) do
    reply =
      case Repo.get_by(User, username: username) do
        nil ->
          {:error, :user_not_found}

        user ->
          # Fetch in-memory metadata
          user_key = String.to_atom("#{username}_metadata")

          metadata =
            case :ets.lookup(table, user_key) do
              [{^user_key, meta}] -> meta
              [] -> %{contacts: MapSet.new(), chat_rooms: MapSet.new()}
            end

          user_data = %{
            username: user.username,
            password: user.password_hash,
            contacts: metadata.contacts,
            chat_rooms: metadata.chat_rooms,
            last_seen: user.last_seen
          }

          {:ok, user_data}
      end

    {:reply, reply, table}
  end

  def handle_call({:get_contacts, username}, _from, table) do
    reply =
      case Repo.get_by(User, username: username) do
        nil ->
          {:error, :user_not_found}

        _user ->
          user_key = String.to_atom("#{username}_metadata")

          contacts =
            case :ets.lookup(table, user_key) do
              [{^user_key, meta}] -> MapSet.to_list(meta.contacts)
              [] -> []
            end

          {:ok, contacts}
      end

    {:reply, reply, table}
  end

  def handle_call({:add_contact, username, contact}, _from, table) do
    reply =
      cond do
        username == contact ->
          {:error, :cannot_add_self}

        Repo.get_by(User, username: contact) == nil ->
          {:error, :user_not_found}

        Repo.get_by(User, username: username) == nil ->
          {:error, :user_not_found}

        true ->
          user_key = String.to_atom("#{username}_metadata")

          metadata =
            case :ets.lookup(table, user_key) do
              [{^user_key, meta}] -> meta
              [] -> %{contacts: MapSet.new(), chat_rooms: MapSet.new()}
            end

          updated_metadata = %{metadata | contacts: MapSet.put(metadata.contacts, contact)}
          :ets.insert(table, {user_key, updated_metadata})
          :ok
      end

    {:reply, reply, table}
  end

  def handle_call({:get_chatrooms, username}, _from, table) do
    reply =
      case Repo.get_by(User, username: username) do
        nil ->
          {:error, :user_not_found}

        _user ->
          user_key = String.to_atom("#{username}_metadata")

          chatrooms =
            case :ets.lookup(table, user_key) do
              [{^user_key, meta}] -> MapSet.to_list(meta.chat_rooms)
              [] -> []
            end

          {:ok, chatrooms}
      end

    {:reply, reply, table}
  end

  def handle_call({:add_chatroom, username, chatroom_id}, _from, table) do
    reply =
      case Repo.get_by(User, username: username) do
        nil ->
          {:error, :user_not_found}

        _user ->
          user_key = String.to_atom("#{username}_metadata")

          metadata =
            case :ets.lookup(table, user_key) do
              [{^user_key, meta}] -> meta
              [] -> %{contacts: MapSet.new(), chat_rooms: MapSet.new()}
            end

          updated_metadata = %{metadata | chat_rooms: MapSet.put(metadata.chat_rooms, chatroom_id)}
          :ets.insert(table, {user_key, updated_metadata})
          :ok
      end

    {:reply, reply, table}
  end

  def handle_call({:update_last_seen, username}, _from, table) do
    reply =
      case Repo.get_by(User, username: username) do
        nil ->
          {:error, :user_not_found}

        user ->
          now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          User.update_last_seen(user, now)
          |> Repo.update()
      end

    {:reply, reply, table}
  end
end
