# Configuration for ChatApp

import Config

# Configure logging
config :logger,
  level: :info,
  format: "[$level] $message\n"

# Development environment specific config
if Mix.env() == :dev do
  config :logger,
    level: :debug

  # Hot reload configuration
  config :chat_app,
    hot_reload: true
end

# Test environment specific config
if Mix.env() == :test do
  config :logger,
    level: :warn
end

# Production environment specific config
if Mix.env() == :prod do
  config :logger,
    level: :info
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

  # Database (if using Ecto in the future)
  repo: ChatApp.Repo
