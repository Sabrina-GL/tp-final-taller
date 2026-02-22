defmodule ChatApp.Repo do
  @moduledoc """
  Módulo de repositorio para interactuar con la base de datos utilizando Ecto.
  """
  use Ecto.Repo,
    otp_app: :chat_app,
    adapter: Ecto.Adapters.Postgres
end
