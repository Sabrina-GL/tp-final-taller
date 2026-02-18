defmodule ChatApp.Accounts do
  # use GenServer
  import Ecto.Query
  alias ChatApp.{Repo, ChatManager}
  alias ChatApp.Schemas.{User, Contact}

  def register_user(username, password) do
    with :ok <- validate_registration(username, password),
         false <- account_exists?(username) do
      hashed = Bcrypt.hash_pwd_salt(password)
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      changeset =
        User.changeset(%User{}, %{
          username: username,
          password_hash: hashed,
          last_seen: now
        })

      with {:ok, _user} <- Repo.insert(changeset) do
        :ok
      else
        {:error, _changeset} ->
          {:error, :registration_failed}
      end
    else
      {:error, reason} ->
        {:error, reason}

      true ->
        {:error, :user_exists}
    end
  end

  defp validate_registration(username, password) do
    cond do
      not is_binary(username) or String.trim(username) == "" ->
        {:error, :invalid_username}

      String.length(username) < 3 ->
        {:error, :username_too_short}

      not is_binary(password) or String.length(password) < 6 ->
        {:error, :password_too_short}

      true ->
        :ok
    end
  end

  def account_exists?(username) do
    Repo.get_by(User, username: username) != nil
  end

  def authenticate_user(username, password) do
    with {:ok, user} <- get_user(username),
         true <- Bcrypt.verify_pass(password, user.password_hash) do
      update_last_seen(username)
    else
      {:error, _} -> {:error, :invalid_credentials}
      false -> {:error, :invalid_credentials}
    end
  end

  def get_user(username) do
    case Repo.get_by(User, username: username) do
      nil ->
        {:error, :user_not_found}

      user ->
        with {:ok, contacts} <- get_contacts(username),
             chatrooms <- ChatManager.get_user_chatrooms(username) do
          user_data = %{
            username: user.username,
            password_hash: user.password_hash,
            last_seen: user.last_seen,
            contacts: contacts,
            chatrooms: chatrooms
          }

          {:ok, user_data}
        end
    end
  end

  def get_contacts(username) do
    with %User{id: user_id} <- Repo.get_by(User, username: username) do
      contacts =
        Contact
        |> where([c], c.user_id == ^user_id and c.status == "active")
        |> join(:inner, [c], u in User, on: c.contact_id == u.id)
        |> order_by([_c, u], asc: u.username)
        |> select([_c, u], u.username)
        |> Repo.all()

      {:ok, contacts}
    else
      nil -> {:error, :user_not_found}
    end
  end

  def get_contacts_who_added_user(username) do
    with %User{id: user_id} <- Repo.get_by(User, username: username) do
      contacts =
        Contact
        |> where([c], c.contact_id == ^user_id and c.status == "active")
        |> join(:inner, [c], u in User, on: c.user_id == u.id)
        |> order_by([_c, u], asc: u.username)
        |> select([_c, u], u.username)
        |> Repo.all()

      {:ok, contacts}
    else
      nil -> {:error, :user_not_found}
    end
  end

  def add_contact(username, contact) do
    if username == contact do
      {:error, :cannot_add_self}
    else
      with false <- interaction_blocked?(username, contact) do
        add_contact_to_db(username, contact)
      else
        true -> {:error, :contact_blocked}
      end
    end
  end

  def block_contact(username, contact) do
    if username == contact do
      {:error, :cannot_block_self}
    else
      block_contact_in_db(username, contact)
    end
  end

  defp add_contact_to_db(username, contact) do
    with %User{id: user_id} <- Repo.get_by(User, username: username),
         %User{id: contact_id} <- Repo.get_by(User, username: contact),
         false <- contact_already_added?(user_id, contact_id) do
      %Contact{}
      |> Contact.changeset(%{
        user_id: user_id,
        contact_id: contact_id
      })
      |> Repo.insert()

      :ok
    else
      nil -> {:error, :user_not_found}
      true -> {:error, :contact_already_exists}
    end
  end

  defp block_contact_in_db(username, contact) do
    with %User{id: user_id} <- Repo.get_by(User, username: username),
         %User{id: contact_id} <- Repo.get_by(User, username: contact) do
      case Repo.get_by(Contact, user_id: user_id, contact_id: contact_id) do
        nil ->
          %Contact{}
          |> Contact.changeset(%{user_id: user_id, contact_id: contact_id, status: "blocked"})
          |> Repo.insert()

        relation ->
          relation
          |> Contact.changeset(%{status: "blocked"})
          |> Repo.update()
      end

      :ok
    else
      nil -> {:error, :user_not_found}
    end
  end

  defp contact_already_added?(user_id, contact_id) do
    Contact
    |> where([c], c.user_id == ^user_id and c.contact_id == ^contact_id)
    |> Repo.exists?()
  end

  def interaction_blocked?(username1, username2) do
    with %User{id: user1_id} <- Repo.get_by(User, username: username1),
         %User{id: user2_id} <- Repo.get_by(User, username: username2) do
      Contact
      |> where(
        [c],
        (c.user_id == ^user1_id and c.contact_id == ^user2_id and c.status == "blocked") or
          (c.user_id == ^user2_id and c.contact_id == ^user1_id and c.status == "blocked")
      )
      |> Repo.exists?()
    else
      _ -> false
    end
  end

  def blocked_with_any?(username, participants) when is_list(participants) do
    participants
    |> Enum.reject(&(&1 == username))
    |> Enum.any?(fn participant -> interaction_blocked?(username, participant) end)
  end

  def has_blocked_pair?(participants) when is_list(participants) do
    pairs =
      for a <- participants,
          b <- participants,
          a < b,
          do: {a, b}

    Enum.any?(pairs, fn {a, b} -> interaction_blocked?(a, b) end)
  end

  def update_last_seen(username) do
    case Repo.get_by(User, username: username) do
      nil ->
        {:error, :user_not_found}

      user ->
        # Update last_seen timestamp (truncate microseconds)
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

        User.update_last_seen(user, now)
        |> Repo.update()

        :ok
    end
  end

  def last_seen(username) do
    case Repo.get_by(User, username: username) do
      nil ->
        {:error, :user_not_found}

      user ->
        {:ok, user.last_seen}
    end
  end
end
