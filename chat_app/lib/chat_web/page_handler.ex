defmodule ChatWeb.PageHandler do
  def init(req, _opts) do
    path =
      :chat_app
      |> :code.priv_dir()
      |> Path.join("static/index.html")

    body = File.read!(path)

    req =
      :cowboy_req.reply(
        200,
        %{"content-type" => "text/html"},
        body,
        req
      )

    {:ok, req, nil}
  end
end
