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
        send_json_resp(conn, 200, %{"status" => "ok", "message" => "User registered successfully"})

      {:error, reason} ->
        send_json_resp(conn, 400, %{"status" => "error", "error" => to_string(reason)})
    end
  end

  post "/api/login" do
    %{"username" => user, "password" => pass} = conn.body_params

    case ChatApp.Accounts.authenticate_user(user, pass) do
      :ok ->
        send_json_resp(conn, 200, %{"status" => "ok", "message" => "Login successful"})

      {:error, reason} ->
        send_json_resp(conn, 401, %{"status" => "error", "error" => to_string(reason)})
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

  get "/uploads/:filename" do
    filename = conn.params["filename"]
    file_path = ChatApp.FileManager.get_file_path("uploads/#{filename}")

    if File.exists?(file_path) do
      conn
      |> Plug.Conn.put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
      |> send_file(200, file_path)
    else
      send_resp(conn, 404, "File not found")
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  defp send_json_resp(conn, status, data) do
    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(status, Jason.encode!(data))
  end
end
