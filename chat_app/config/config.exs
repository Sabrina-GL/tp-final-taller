# Configuration for ChatApp

import Config

# Configure logging
config :logger,
  level: :info,
  format: "[$level] $message\n"

# Configure Ecto
config :chat_app, ecto_repos: [ChatApp.Repo]

config :chat_app, ChatApp.Repo,
  database: "chat_app.db",
  pool_size: 10,
  pragma_foreign_keys: true

# Development environment specific config
if Mix.env() == :dev do
  config :logger,
    level: :debug

  config :chat_app, ChatApp.Repo,
    database: System.get_env("CHAT_APP_DB_PATH", "chat_app_dev.db")

  # Hot reload configuration
  config :chat_app,
    hot_reload: true
end

# Test environment specific config
if Mix.env() == :test do
  config :logger,
    level: :warning

  config :chat_app, ChatApp.Repo,
    database: ":memory:",
    pool_size: 1
end

# Production environment specific config
if Mix.env() == :prod do
  config :logger,
    level: :info

  config :chat_app, ChatApp.Repo,
    database: System.get_env("CHAT_APP_DB_PATH", "chat_app_prod.db")
end

# Application config
config :chat_app,
  # WebSocket configuration
  websocket_port: 4000,
  websocket_host: "127.0.0.1",

  # Message history limit
  message_history_limit: 10,

  # Activity tracker settings
  activity_timeout: 300_000,  # 5 minutes in milliseconds

  # DB migrations on app boot (dev/prod)
  auto_migrate_on_start:
    System.get_env("AUTO_MIGRATE_ON_START", "true") in ["true", "1", "yes"],

  # Database (if using Ecto in the future)
  repo: ChatApp.Repo

if Mix.env() == :test do
  config :chat_app,
    auto_migrate_on_start: false,
    websocket_port: 4001  # Usar puerto diferente en tests
end
