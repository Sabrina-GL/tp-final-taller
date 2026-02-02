defmodule ChatWeb.PageHandler do
  @behaviour :cowboy_handler

  def init(req, state) do
    path = :cowboy_req.path(req)

    case path do
      # Redirige a página de registro
      "/" ->
        serve(req, state, "static/register.html")

      "/register" ->
        serve(req, state, "static/register.html")

      "/login" ->
        serve(req, state, "static/login.html")

      "/index.html" ->
        serve(req, state, "static/index.html")

      _ ->
        req = :cowboy_req.reply(404, %{}, "Not Found", req)
        {:ok, req, state}
    end
  end

  defp serve(req, state, file_path) do
    path =
      :chat_app
      |> :code.priv_dir()
      |> Path.join(file_path)

    body = File.read!(path)

    req =
      :cowboy_req.reply(
        200,
        %{"content-type" => "text/html"},
        body,
        req
      )

    {:ok, req, state}
  end
end
