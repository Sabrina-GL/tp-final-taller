defmodule ChatApp.DataCase do
  use ExUnit.CaseTemplate

  alias ChatApp.{Repo, Accounts, ActivityServer, ActivityRegistry, ChatRoomsRegistry}
  alias ChatApp.Schemas.{User, Message, Chatroom, Contact}

  using opts do
    quote do
      use ExUnit.Case, unquote(opts)

      alias ChatApp.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import ChatApp.DataCase
    end
  end

  setup tags do
    # Checkout del sandbox
    case Ecto.Adapters.SQL.Sandbox.checkout(Repo) do
      :ok -> :ok
      {:already, :owner} -> :ok
    end

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    end

    # Matar todos los procesos antes de cada test
    kill_all_chatroom_servers()
    kill_all_activity_servers()
    kill_all_socket_handlers()

    :ok
  end

  # ========== Helpers públicas ==========
  def create_test_users(users) when is_list(users) do
    Enum.each(users, fn username ->
      Accounts.register_user(username, "pass123")
    end)
  end

  def start_activity_servers(users) when is_list(users) do
    Enum.each(users, fn username ->
      case ActivityServer.start_link(username) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end)
  end

  # ========== Cleanup de procesos ==========
  def kill_all_chatroom_servers do
    case Registry.select(ChatRoomsRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$2"]}]) do
      list when is_list(list) ->
        Enum.each(list, fn
          pid when is_pid(pid) -> Process.exit(pid, :kill)
          _ -> :ok
        end)

      _ ->
        :ok
    end
  end

  def kill_all_activity_servers do
    case Registry.select(ActivityRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$1"]}]) do
      list when is_list(list) ->
        Enum.each(list, fn
          {pid, _} when is_pid(pid) -> Process.exit(pid, :kill)
          _ -> :ok
        end)

      _ ->
        :ok
    end
  end

  def kill_all_socket_handlers do
    case Registry.select(ChatApp.UsersRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$2"]}]) do
      list when is_list(list) ->
        Enum.each(list, fn
          pid when is_pid(pid) -> Process.exit(pid, :kill)
          _ -> :ok
        end)

      _ ->
        :ok
    end
  end

  # ========== Cleanup de DB ==========
  def cleanup_database do
    Repo.delete_all(Message)
    Repo.delete_all(Contact)
    Repo.delete_all(Chatroom)
    Repo.delete_all(User)
  end
end
