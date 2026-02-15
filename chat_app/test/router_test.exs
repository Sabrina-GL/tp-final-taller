defmodule ChatWeb.RouterTest do
  use ExUnit.Case, async: false
  import Plug.Test
  import Plug.Conn

  setup do
    # Clear ETS table before each test
    case :ets.whereis(:accounts) do
      :undefined -> :ok
      tid -> :ets.delete_all_objects(tid)
    end

    # Register test users
    ChatApp.Accounts.register_user("testuser", "pass123")
    ChatApp.ActivityTracker.user_online("testuser")
    :ok
  end

  describe "Router HTTP requests" do
    test "GET / returns register.html" do
      conn = conn(:get, "/")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 200
      assert conn.resp_body =~ "Registro"
    end

    test "GET /login returns login page" do
      conn = conn(:get, "/login")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 200
      assert conn.resp_body =~ "Inicio de Sesión"
    end

    test "GET /register returns register page" do
      conn = conn(:get, "/register")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 200
      assert conn.resp_body =~ "Registro"
    end

    test "POST /api/register creates new user" do
      body = Jason.encode!(%{username: "newuser", password: "pass123"})
       conn =
        conn(:post, "/api/register", body)
        |> put_req_header("content-type", "application/json")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 200
      assert conn.resp_body =~ "User registered successfully"
    end

    test "POST /api/register with existing user fails" do
      ChatApp.Accounts.register_user("existinguser", "pass123")
      body = Jason.encode!(%{username: "existinguser", password: "pass123"})
      conn =
        conn(:post, "/api/register", body)
        |> put_req_header("content-type", "application/json")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 400
      assert conn.resp_body =~ "Registration failed"
    end

    test "POST /api/login with valid credentials succeeds" do
      body = Jason.encode!(%{username: "testuser", password: "pass123"})
      conn =
        conn(:post, "/api/login", body)
        |> put_req_header("content-type", "application/json")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 200
      assert conn.resp_body =~ "Login successful"
    end

    test "POST /api/login with invalid credentials fails" do
      body = Jason.encode!(%{username: "testuser", password: "wrongpass"})
      conn =
        conn(:post, "/api/login", body)
        |> put_req_header("content-type", "application/json")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 401
      assert conn.resp_body =~ "Login failed"
    end

    test "GET /api/status for online user" do
      conn = conn(:get, "/api/status?user=testuser")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["user"] == "testuser"
      assert response["online"] == true
    end

    test "GET /api/status for offline user" do
      ChatApp.Accounts.register_user("offlineuser", "pass123")
      ChatApp.ActivityTracker.user_offline("offlineuser")
      conn = conn(:get, "/api/status?user=offlineuser")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["user"] == "offlineuser"
      assert response["online"] == false
    end

    test "GET /api/status without user parameter" do
      conn = conn(:get, "/api/status")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 400
      response = Jason.decode!(conn.resp_body)
      assert response["error"] == "user parameter required"
    end

    test "GET /unknown returns 404" do
      conn = conn(:get, "/unknown")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 404
    end
  end
end
