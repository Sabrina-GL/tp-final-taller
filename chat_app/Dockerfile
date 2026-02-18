FROM elixir:1.18

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git postgresql-client && \
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
ENV POSTGRES_HOST=postgres
ENV POSTGRES_PORT=5432
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB=chat_app_dev
ENV AUTO_MIGRATE_ON_START=true

EXPOSE 4000

CMD ["mix", "run", "--no-halt"]