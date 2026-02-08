defmodule ChatApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :chat_app,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ChatApp.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Web framework & WebSocket
      {:cowboy, "~> 2.9"},
      {:plug_cowboy, "~> 2.6"},
      {:plug, "~> 1.14"},

      # JSON encoding/decoding
      {:jason, "~> 1.4"},

      # Database
      {:ecto, "~> 3.10"},
      {:ecto_sqlite3, "~> 0.9"},

      # Hashing passwords
      {:bcrypt_elixir, "~> 3.0"},

      # Development tools
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
