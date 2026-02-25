defmodule ChatWeb.Router do
  @moduledoc """
  Módulo de enrutamiento para la aplicación ChatApp.

  Maneja:
  - Rutas HTTP para servir archivos estáticos y manejar solicitudes de registro, inicio de sesión y estado de usuarios.
  - Ruta para actualizar a WebSocket, permitiendo la comunicación en tiempo real entre clientes y el servidor.
  - Rutas para servir archivos subidos por los usuarios.
  """
  use Plug.Router

  # ======= Configuración de plugs ========
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

  # ======= Rutas ========
  get "/" do
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

  # ======= API Endpoints ========
  post "/api/register" do
    %{"username" => user, "password" => pass} = conn.body_params

    case ChatApp.Accounts.register_user(user, pass) do
      :ok ->
        token = ChatApp.AuthToken.issue_token(user)

        send_json_resp(conn, 200, %{
          "status" => "ok",
          "message" => "User registered successfully",
          "user" => user,
          "token" => token
        })

      {:error, reason} ->
        send_json_resp(conn, 400, %{"status" => "error", "error" => to_string(reason)})
    end
  end

  post "/api/login" do
    %{"username" => user, "password" => pass} = conn.body_params

    case ChatApp.Accounts.authenticate_user(user, pass) do
      :ok ->
        token = ChatApp.AuthToken.issue_token(user)

        send_json_resp(conn, 200, %{
          "status" => "ok",
          "message" => "Login successful",
          "user" => user,
          "token" => token
        })

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

  # ====== WebSocket Endpoint ========
  get "/ws" do
    token = conn.params["token"]
    idle_timeout = Application.get_env(:chat_app, :ws_idle_timeout_ms, 900_000)

    with {:ok, user} <- ChatApp.AuthToken.verify_token(token) do
      Plug.Conn.upgrade_adapter(
        conn,
        :websocket,
        {ChatWeb.SocketHandler, %{user: user}, %{idle_timeout: idle_timeout}}
      )
    else
      {:error, :expired_token} -> send_resp(conn, 401, "Token expired")
      {:error, :invalid_token} -> send_resp(conn, 401, "Invalid token")
    end
  end

  # ====== Archivos subidos ======
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

  # ====== 404 ======
  match _ do
    send_resp(conn, 404, "not found")
  end

  # ====== Helpers ======
  defp send_json_resp(conn, status, data) do
    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(status, Jason.encode!(data))
  end
end
