# ChatApp - Backend de Chat en Elixir

## Descripcion

Servidor de chat en tiempo real construido con Elixir + OTP. Usa WebSocket (Cowboy) para comunicacion bidireccional.

## Requisitos

- Elixir >= 1.17
- Erlang/OTP >= 25
- Mix (incluido con Elixir)
- SQLite3 (integrado con Ecto, necesario para persistencia de usuarios y mensajes)

## Inicio rapido

```bash
mix deps.get
mix compile

# Opcion 1: Consola interactiva
iex -S mix

# Opcion 2: En background (sin consola)
mix run --no-halt
```

Servidor disponible en:
- HTTP: http://localhost:4000
- WebSocket: ws://localhost:4000/ws?user=username

## API REST

### Registro
```
POST /api/register
Body: {"username": "user", "password": "pass"}
```

### Login
```
POST /api/login
Body: {"username": "user", "password": "pass"}
```

## WebSocket API

Conectar:
```
ws://localhost:4000/ws?user=username
```

Mensajes soportados:
```json
{
  "action": "send_message",
  "chat_id": "chat_123",
  "msg_content": "Hola!"
}
```

Acciones disponibles:
- get_contacts
- get_chatrooms
- get_messages
- get_status
- add_contact
- create_group_chat
- send_message

## Consola interactiva (IEx)

```elixir
# Registrar usuario
ChatApp.Accounts.register_user("alice", "pass123")
ChatApp.Accounts.register_user("bob", "pass456")

# Crear chat privado
{:ok, chat_id} = ChatApp.ChatManager.get_or_create_private_chat("alice", "bob")

# Enviar mensaje
ChatApp.ChatRoom.add_message(chat_id, "alice", "Hola Bob!")

# Obtener mensajes
ChatApp.ChatRoom.get_messages(chat_id)

# Buscar mensajes
ChatApp.ChatRoom.search_messages(chat_id, "Hola")
```

## Modulos principales

- `ChatApp.Application` - Punto de entrada OTP y supervision
- `ChatApp.Accounts` - Registro y autenticacion de usuarios (con Ecto + SQLite)
- `ChatApp.ChatManager` - Gestor central de conversaciones
- `ChatApp.ChatRoom` - Logica de salas y mensajes (con persistencia en SQLite)
- `ChatApp.ActivityTracker` - Estado activo/inactivo
- `ChatApp.ChatRoomSupervisor` - Supervisor dinamico de salas
- `ChatApp.Repo` - Repositorio Ecto para SQLite
- `ChatApp.Schemas.User` - Schema de usuarios
- `ChatApp.Schemas.Message` - Schema de mensajes
- `ChatWeb.Router` - Rutas HTTP y upgrade a WebSocket
- `ChatWeb.SocketHandler` - Manejo de conexiones WebSocket

## Archivos estaticos

Ubicacion: `priv/static/`
- `index.html` - Pagina principal
- `login.html` - Login
- `register.html` - Registro
- `application.js` - Cliente web

## Configuracion

### Puerto del servidor
Edita `lib/chat_app/application.ex`:
```elixir
Plug.Cowboy.child_spec(
  scheme: :http,
  plug: ChatWeb.Router,
  options: [port: 4000]
)
```

### Base de datos
Configurar en `config/config.exs` (si se usa persistencia):
```elixir
config :chat_app, ChatApp.Repo,
  database: "chat_app.db",
  pool_size: 10
```

## Desarrollo y testing

```bash
mix test
mix test --trace
mix test test/chat_app_test.exs

mix format
mix compile --warnings-as-errors
mix dialyzer
```

## Troubleshooting

### Port already in use
```bash
lsof -i :4000
kill -9 <PID>
```

### Errores de compilacion
```bash
mix clean
mix deps.get
mix compile
```

### Base de datos corrupta
```bash
rm -f chat_app.db
mix compile
```

## Enlaces útiles

### Documentación del Proyecto (nivel superior)
- [README principal](../README.md) - Visión general y características
- [DEMO.md](../DEMO.md) - Guía paso a paso para demostración en vivo
- [CLIENT_README.md](../CLIENT_README.md) - Documentación del cliente Python
- [COBERTURA_TESTS.md](../COBERTURA_TESTS.md) - Análisis de cobertura de tests (87.37%)

### Documentación de Desarrollo
- [ARQUITECTURA.md](../ARQUITECTURA.md) - Decisiones de arquitectura y diagrama
- [DESARROLLO.md](../DESARROLLO.md) - Lineamientos de desarrollo
- [ESTADO.md](../ESTADO.md) - Resumen de features implementados vs pendientes
- [consigna-tp-final.txt](../consigna-tp-final.txt) - Enunciado original del trabajo

- [ESTADO.md](../ESTADO.md)

