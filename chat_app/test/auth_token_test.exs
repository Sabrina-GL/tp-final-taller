defmodule ChatApp.AuthTokenTest do
  use ExUnit.Case, async: true

  alias ChatApp.AuthToken

  test "issue_token and verify_token returns user" do
    token = AuthToken.issue_token("alice")

    assert is_binary(token)
    assert {:ok, "alice"} = AuthToken.verify_token(token)
  end

  test "verify_token returns invalid_token for malformed token" do
    assert {:error, :invalid_token} = AuthToken.verify_token("not-a-token")
  end

  test "verify_token returns invalid_token for missing token" do
    assert {:error, :invalid_token} = AuthToken.verify_token(nil)
  end
end
