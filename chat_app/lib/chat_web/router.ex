defmodule ChatWeb.Router do
  use Plug.Router

  plug(Plug.Static,
    at: "/static",
    from: :chat_app,
    gzip: false
  )

  plug(Plug.Logger)
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :json, :multipart],
    json_decoder: Jason
  )

  plug(:dispatch)

  get "/" do
    # conn
    # |> put_resp_content_type("location", "/register")
    # |> send_resp(302, "")
    send_file(conn, 200, "priv/static/register.html")
  end

  get "/register" do
    send_file(conn, 200, "priv/static/register.html")
  end

  get "/login" do
    send_file(conn, 200, "priv/static/login.html")
  end

  get "/index" do
    send_file(conn, 200, "priv/static/index.html")
  end

  post "/api/register" do
    %{"username" => user, "password" => pass} = conn.body_params

    case ChatApp.Accounts.register_user(user, pass) do
      :ok ->
        send_resp(conn, 200, "User registered successfully")

      {:error, reason} ->
        send_resp(conn, 400, "Registration failed: #{reason}")
    end
  end

  post "/api/login" do
    %{"username" => user, "password" => pass} = conn.body_params

    case ChatApp.Accounts.authenticate_user(user, pass) do
      :ok ->
        send_resp(conn, 200, "Login successful")

      {:error, reason} ->
        send_resp(conn, 401, "Login failed: #{reason}")
    end
  end

  get "/api/status" do
    user = conn.params["user"]

    if user && user != "" do
      online? = ChatApp.ActivityServer.is_online?(user)

      last_seen =
        if online? do
          ChatApp.ActivityServer.last_seen(user)
        else
          case ChatApp.Accounts.last_seen(user) do
            {:ok, datetime} -> datetime
            {:error, _} -> nil
          end
        end

      send_resp(
        conn,
        200,
        Jason.encode!(%{user: user, online: online?, last_seen: last_seen})
      )
    else
      send_resp(conn, 400, Jason.encode!(%{error: "user parameter required"}))
    end
  end

  get "/ws" do
    # Plug.Conn.upgrade_adapter(conn, :websocket, {ChatWeb.SocketHandler, %{}, %{}})
    user = conn.params["user"]

    if user && user != "" do
      Plug.Conn.upgrade_adapter(
        conn,
        :websocket,
        {ChatWeb.SocketHandler, %{user: user}, %{}}
      )
    else
      send_resp(conn, 400, "Missing user")
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
