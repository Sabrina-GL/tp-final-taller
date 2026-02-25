defmodule ChatWeb.RouterTest do
  use ChatApp.DataCase, async: false
  import Plug.Test
  import Plug.Conn

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
      data = Jason.decode!(conn.resp_body)
      assert data["status"] == "ok"
      assert is_binary(data["token"])
      assert data["user"] == "newuser"
    end

    test "POST /api/register with existing user fails" do
      ChatApp.Accounts.register_user("existinguser", "pass123")
      body = Jason.encode!(%{username: "existinguser", password: "pass123"})

      conn =
        conn(:post, "/api/register", body)
        |> put_req_header("content-type", "application/json")

      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 400
      data = Jason.decode!(conn.resp_body)
      assert data["status"] == "error"
    end

    test "POST /api/login with valid credentials succeeds" do
      create_test_users(["testuser"])
      start_activity_servers(["testuser"])
      ChatApp.ActivityServer.user_online("testuser")
      body = Jason.encode!(%{username: "testuser", password: "pass123"})

      conn =
        conn(:post, "/api/login", body)
        |> put_req_header("content-type", "application/json")

      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 200
      data = Jason.decode!(conn.resp_body)
      assert data["status"] == "ok"
      assert is_binary(data["token"])
      assert data["user"] == "testuser"
    end

    test "POST /api/login with invalid credentials fails" do
      body = Jason.encode!(%{username: "testuser", password: "wrongpass"})

      conn =
        conn(:post, "/api/login", body)
        |> put_req_header("content-type", "application/json")

      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 401
      data = Jason.decode!(conn.resp_body)
      assert data["status"] == "error"
    end

    test "GET /ws without token returns 401" do
      conn = conn(:get, "/ws")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 401
      assert conn.resp_body == "Invalid token"
    end

    test "GET /ws with invalid token returns 401" do
      conn = conn(:get, "/ws?token=invalid")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 401
      assert conn.resp_body == "Invalid token"
    end

    test "GET /api/status for online user" do
      create_test_users(["testuser"])
      start_activity_servers(["testuser"])
      ChatApp.ActivityServer.user_online("testuser")
      conn = conn(:get, "/api/status?user=testuser")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["user"] == "testuser"
      assert response["online"] == true
    end

    test "GET /api/status for offline user" do
      ChatApp.Accounts.register_user("offlineuser", "pass123")
      Registry.unregister(ChatApp.UsersRegistry, "offlineuser")
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

    test "POST /api/register with short username fails" do
      body = Jason.encode!(%{username: "ab", password: "pass123"})

      conn =
        conn(:post, "/api/register", body)
        |> put_req_header("content-type", "application/json")

      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 400
      data = Jason.decode!(conn.resp_body)
      assert data["status"] == "error"
    end

    test "POST /api/register with short password fails" do
      body = Jason.encode!(%{username: "validuser", password: "12345"})

      conn =
        conn(:post, "/api/register", body)
        |> put_req_header("content-type", "application/json")

      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 400
      data = Jason.decode!(conn.resp_body)
      assert data["status"] == "error"
    end

    test "POST /api/login with non-existent user fails" do
      body = Jason.encode!(%{username: "nonexistent", password: "pass123"})

      conn =
        conn(:post, "/api/login", body)
        |> put_req_header("content-type", "application/json")

      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 401
      data = Jason.decode!(conn.resp_body)
      assert data["status"] == "error"
    end

    test "GET /api/status for non-existent user returns defaults" do
      conn = conn(:get, "/api/status?user=nonexistent")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["user"] == "nonexistent"
      assert response["online"] == false
    end

    test "GET /index returns index.html" do
      conn = conn(:get, "/index")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 200
      assert conn.resp_body =~ "Chat"
    end

    test "PUT request returns 404" do
      conn = conn(:put, "/api/register")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 404
    end

    test "DELETE request returns 404" do
      conn = conn(:delete, "/api/user/test")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 404
    end

    test "PATCH request returns 404" do
      conn = conn(:patch, "/api/user/test")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 404
    end

    test "POST /api/unknown endpoint returns 404" do
      body = Jason.encode!(%{data: "test"})

      conn =
        conn(:post, "/api/unknown", body)
        |> put_req_header("content-type", "application/json")

      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 404
    end

    test "GET request without query params to /api/status" do
      conn = conn(:get, "/api/status")
      conn = ChatWeb.Router.call(conn, ChatWeb.Router.init([]))

      assert conn.status == 400
      response = Jason.decode!(conn.resp_body)
      assert response["error"] == "user parameter required"
    end

    test "POST /api/register with empty body fails" do
      conn =
        conn(:post, "/api/register", "")
        |> put_req_header("content-type", "application/json")

      assert_raise Plug.Conn.WrapperError, fn ->
        ChatWeb.Router.call(conn, ChatWeb.Router.init([]))
      end
    end

    test "POST /api/login with empty body fails" do
      conn =
        conn(:post, "/api/login", "")
        |> put_req_header("content-type", "application/json")

      assert_raise Plug.Conn.WrapperError, fn ->
        ChatWeb.Router.call(conn, ChatWeb.Router.init([]))
      end
    end
  end
end
