# Guía de Desarrollo - Sistema de Chat

## Inicio Rápido para Desarrolladores

### Requisitos
- Elixir 1.17+
- Erlang/OTP 25+
- Editor recomendado: VS Code con extensión ElixirLS

### Setup Inicial

```bash
# 1. Clonar repositorio
git clone <url>
cd tp-final-taller/chat_app

# 2. Instalar dependencias
mix deps.get

# 3. Compilar
mix compile

# 4. Ejecutar servidor
iex -S mix

# En otra terminal, probar WebSocket
# curl http://localhost:4000
```

## Estructura OTP

### Jerarquía de Supervisores

```
ChatApp.Supervisor (one_for_one)
├── Registry (UsersRegistry)
├── Registry (ChatRoomsRegistry)
├── Registry (ActivityRegistry)
├── ChatApp.ActivitySupervisor (DynamicSupervisor)
│   └── ChatApp.ActivityServer (GenServer) × N usuarios
├── ChatApp.ChatRoomSupervisor (DynamicSupervisor)
│   └── ChatApp.ChatRoomServer (GenServer) × N salas
└── Plug.Cowboy (servidor HTTP)
```

### Flujos de Datos

#### 1. Registro de Usuario
```
POST /api/register
    ↓
ChatWeb.Router.post("/api/register")
    ↓
ChatApp.Accounts.register_user/2
  ↓
ChatApp.Repo.insert(User)  (persistencia en PostgreSQL)
    ↓
{:ok, user}  (respuesta)
```

#### 2. Mensaje en WebSocket
```
WebSocket msg
    ↓
ChatWeb.SocketHandler.websocket_handle/2
    ↓
Parse JSON
    ↓
ChatApp.ChatRoomServer.add_message/3
    ↓
Broadcast a clientes conectados
```

#### 3. Rastreo de Actividad
```
Usuario conecta
  ↓
Registry registra conexión (UsersRegistry)
  ↓
ActivityServer actualiza estado online/offline y last_seen
```

## Mejoras Futuras

### Persistencia (Ecto + PostgreSQL)

```elixir
# Crear migration
mix ecto.gen.migration create_users

# Agregar a config:
config :chat_app, ecto_repos: [ChatApp.Repo]

config :chat_app, ChatApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  database: "chat_app_dev",
  pool_size: 10
```

### Validaciones

```elixir
# Agregar en Accounts
defp validate_username(username) do
  if String.length(username) >= 3 do
    :ok
  else
    {:error, "Username must be at least 3 characters"}
  end
end
```

### Manejo de Errores

- [ ] Timeout en conexiones WebSocket
- [ ] Recuperación de desconexiones
- [ ] Limpieza de salas vacías
- [ ] Rate limiting

### Características Avanzadas

#### Bloquear Contactos
```elixir
ChatApp.Accounts.block_user(blocker, blocked)
ChatApp.Accounts.is_blocked?(user1, user2)
```

#### Borrar Mensajes
```elixir
ChatApp.ChatManager.delete_message(chat_id, message_id)
```

#### Envío de Archivos
```elixir
# Implementado con Base64 over WebSocket
# ChatApp.FileManager - Módulo para gestión de archivos
# ChatWeb.SocketHandler - Action: send_file
# Ver ejemplos en client.py (método send_file)
```

## Testing

### Tipos de Tests

1. **Tests por archivo/módulo**
   ```bash
  mix test test/accounts_test.exs
   ```

2. **Suite completa**
   ```bash
  mix test
   ```

3. **Property-Based Tests (opcional)**
   - Agregar dependencia `StreamData`

### Cobertura
```bash
mix test --cover
```

La cobertura debe tomarse de la última corrida local.
Objetivo original: >= 80% ✅

## Debugging

### En iex
```elixir
# Ver estado de un GenServer
:sys.get_state(ChatApp.ChatManager)

# Trace de procesos
:sys.trace(ChatApp.ChatManager, true)

# Ver registro de usuarios online
Registry.lookup(ChatApp.UsersRegistry, "alice")
```

### Logs
```bash
# Debug mode
iex -S mix --logger-level debug

# Logs en archivo
export ELIXIR_ERL_OPTIONS="+K true"
```

## Buenas Prácticas

1. **Naming**: `module_function_returns` (e.g., `user_online_ok`)
2. **Pattern Matching**: Usar siempre que sea posible
3. **Pipe Operator**: Encadenar transformaciones
4. **Guards**: Para validaciones de tipos
5. **Documentation**: Documentar funciones públicas con @doc

### Ejemplo de Función Bien Documentada

```elixir
@doc """
Sends a message to a chat room.

## Parameters
  - chat_id: ID of the chat room
  - user: Username of the sender
  - content: Message content

## Returns
  - `:ok` on success
  - `{:error, reason}` on failure
"""
def send_message(chat_id, user, content) when is_binary(content) do
  # implementation
end
```

## Deployment

### Producción
```bash
# Compilar para producción
MIX_ENV=prod mix compile

# Generar release
MIX_ENV=prod mix release

# Ejecutar release
_build/prod/rel/chat_app/bin/chat_app start
```

### Docker (Opcional)

El proyecto corre con PostgreSQL; Docker incluye el servicio de base de datos.
Si prefieres workflow dockerizado (recomendado para entorno reproducible):

```bash
make setup-docker          # agrega usuario a grupo docker
newgrp docker              # activa grupo sin relogin
make setup-dockerized      # build + up + status
make docker-logs           # ver logs del backend
make docker-down           # detener contenedores
```

**Alternativa sin reiniciar sesión:**
```bash
make setup-docker
make setup-dockerized-sudo # usa sudo directamente
```

Compose definido en `docker-compose.yml`.

## Documentación Generada

```bash
# Generar docs con ExDoc
mix docs

# Ver en navegador
open doc/index.html
```

## Resources

- [Elixir Docs](https://elixir-lang.org/docs.html)
- [Erlang/OTP Guide](https://erlang.org/doc/)
- [Cowboy Documentation](https://ninenines.eu/docs/)
- [Plug Documentation](https://github.com/elixir-plug/plug)
