defmodule ChatApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChatApp.Repo,
      {Registry, keys: :unique, name: ChatApp.UsersRegistry},
      {Registry, keys: :unique, name: ChatApp.ChatRoomsRegistry},
      ChatApp.Accounts,
      ChatApp.ChatManager,
      ChatApp.ActivityTracker,
      ChatApp.ChatRoomSupervisor,
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: ChatWeb.Router,
        options: [port: 4000]
      )
    ]

    opts = [strategy: :one_for_one, name: ChatApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
