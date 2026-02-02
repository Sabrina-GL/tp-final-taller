defmodule ChatApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    dispatcher =
      :cowboy_router.compile([
        {:_,
         [
           {"/", ChatWeb.PageHandler, []},
           {"/ws", ChatWeb.SocketHandler, []},
           {"/static/[...]", :cowboy_static, {:priv_dir, :chat_app, "static"}}
         ]}
      ])

    {:ok, _} =
      :cowboy.start_clear(
        :chat_app_http,
        [{:port, 4000}],
        %{env: %{dispatch: dispatcher}}
      )

    children = [
      {Registry, keys: :unique, name: ChatApp.UsersOnlineRegistry},
      ChatApp.Accounts,
      ChatApp.ChatManager,
      ChatApp.ActivityTracker,
      ChatApp.ChatRoomSupervisor
    ]

    opts = [strategy: :one_for_one, name: ChatApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
