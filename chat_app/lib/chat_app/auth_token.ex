defmodule ChatApp.AuthToken do
  @moduledoc """
  Maneja emisión y verificación de tokens firmados para autenticación WebSocket.
  """

  alias Plug.Crypto.MessageVerifier

  @default_ttl_seconds 86_400

  def issue_token(user) when is_binary(user) and user != "" do
    expires_at = System.system_time(:second) + token_ttl_seconds()

    payload =
      Jason.encode!(%{
        "user" => user,
        "exp" => expires_at
      })

    MessageVerifier.sign(payload, secret())
  end

  def verify_token(token) when is_binary(token) and token != "" do
    case MessageVerifier.verify(token, secret()) do
      :error ->
        {:error, :invalid_token}

      {:ok, payload} ->
        with {:ok, data} <- Jason.decode(payload),
             {:ok, user} <- validate_user(data),
             :ok <- validate_expiration(data) do
          {:ok, user}
        else
          {:error, _} = error -> error
        end
    end
  rescue
    _ -> {:error, :invalid_token}
  end

  def verify_token(_), do: {:error, :invalid_token}

  defp validate_user(%{"user" => user}) when is_binary(user) and user != "", do: {:ok, user}
  defp validate_user(_), do: {:error, :invalid_token}

  defp validate_expiration(%{"exp" => exp}) when is_integer(exp) do
    if exp > System.system_time(:second), do: :ok, else: {:error, :expired_token}
  end

  defp validate_expiration(_), do: {:error, :invalid_token}

  defp token_ttl_seconds do
    Application.get_env(:chat_app, :ws_token_ttl_seconds, @default_ttl_seconds)
  end

  defp secret do
    Application.get_env(:chat_app, :ws_token_secret, "change_me_in_prod")
  end
end
