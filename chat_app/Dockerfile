FROM elixir:1.18

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git sqlite3 libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY mix.exs mix.lock* ./
COPY config ./config

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

COPY lib ./lib
COPY priv ./priv

RUN mix compile

ENV MIX_ENV=dev
ENV CHAT_APP_DB_PATH=/app/data/chat_app_dev.db
ENV AUTO_MIGRATE_ON_START=true

EXPOSE 4000

CMD ["mix", "run", "--no-halt"]