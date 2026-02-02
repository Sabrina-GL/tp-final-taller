defmodule ChatApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    dispatcher =
      :cowboy_router.compile([
        {:_,
         [
           {"/ws", SocketHandler, []}
         ]}
      ])

    {:ok, _} =
      :cowboy.start_clear(
        :chat_app_http,
        [{:port, 4000}],
        %{env: %{dispatch: dispatcher}}
      )

    children = []

    opts = [strategy: :one_for_one, name: ChatApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
