# Configuration for ChatApp

import Config

# Configure logging
config :logger,
  level: :info,
  format: "[$level] $message\n"

# Configure Ecto
config :chat_app, ecto_repos: [ChatApp.Repo]

config :chat_app, ChatApp.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  port: String.to_integer(System.get_env("POSTGRES_PORT", "5432")),
  database: System.get_env("POSTGRES_DB", "chat_app_dev"),
  maintenance_database: System.get_env("POSTGRES_MAINTENANCE_DB", "postgres"),
  pool_size: 10,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

# Development environment specific config
if Mix.env() == :dev do
  config :logger,
    level: :debug

  config :chat_app, ChatApp.Repo, database: System.get_env("POSTGRES_DB", "chat_app_dev")

  # Hot reload configuration
  config :chat_app,
    hot_reload: true
end

# Test environment specific config
if Mix.env() == :test do
  config :logger,
    level: :warning

  config :chat_app, ChatApp.Repo,
    username: System.get_env("POSTGRES_TEST_USER", System.get_env("POSTGRES_USER", "postgres")),
    password:
      System.get_env("POSTGRES_TEST_PASSWORD", System.get_env("POSTGRES_PASSWORD", "postgres")),
    hostname: System.get_env("POSTGRES_TEST_HOST", System.get_env("POSTGRES_HOST", "localhost")),
    port:
      String.to_integer(
        System.get_env("POSTGRES_TEST_PORT", System.get_env("POSTGRES_PORT", "5432"))
      ),
    database: System.get_env("POSTGRES_TEST_DB", "chat_app_test"),
    maintenance_database:
      System.get_env(
        "POSTGRES_TEST_MAINTENANCE_DB",
        System.get_env("POSTGRES_MAINTENANCE_DB", "postgres")
      ),
    pool_size: 2,
    pool: Ecto.Adapters.SQL.Sandbox
end

# Production environment specific config
if Mix.env() == :prod do
  config :logger,
    level: :info

  config :chat_app, ChatApp.Repo,
    username: System.get_env("POSTGRES_USER", "postgres"),
    password: System.get_env("POSTGRES_PASSWORD", "postgres"),
    hostname: System.get_env("POSTGRES_HOST", "localhost"),
    port: String.to_integer(System.get_env("POSTGRES_PORT", "5432")),
    database: System.get_env("POSTGRES_DB", "chat_app_prod"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE", "10"))
end

# Application config
config :chat_app,
  # WebSocket configuration
  websocket_port: 4000,
  websocket_host: "127.0.0.1",

  # Message history limit
  message_history_limit: 10,

  # Activity tracker settings
  # 5 minutes in milliseconds
  activity_timeout: 300_000,

  # DB migrations on app boot (dev/prod)
  auto_migrate_on_start: System.get_env("AUTO_MIGRATE_ON_START", "true") in ["true", "1", "yes"],

  # Database (if using Ecto in the future)
  repo: ChatApp.Repo

if Mix.env() == :test do
  config :chat_app,
    auto_migrate_on_start: false,
    # Usar puerto diferente en tests
    websocket_port: 4001
end
