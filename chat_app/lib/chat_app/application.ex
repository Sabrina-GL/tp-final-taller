defmodule ChatApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    dispatch =
      :cowboy_router.compile([
        {:_,
         [
           {"/", ChatWeb.PageHandler, []},
           {"/ws", ChatWeb.SocketHandler, []},
           {"/[...]", ChatWeb.PageHandler, []}
         ]}
      ])

    {:ok, _} =
      :cowboy.start_clear(
        :chat_app_http,
        [{:port, 4000}],
        %{env: %{dispatch: dispatch}}
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
