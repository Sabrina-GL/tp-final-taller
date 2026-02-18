# ChatApp - Backend de Chat en Elixir

## Descripcion

Servidor de chat en tiempo real construido con Elixir + OTP. Usa WebSocket (Cowboy) para comunicacion bidireccional.

## Features Implementadas

### Básicas (Mandatorias)
- ✅ Autenticación de usuarios (registro + login)
- ✅ Chats privados entre dos usuarios
- ✅ Chats grupales
- ✅ Envío y recepción de mensajes en tiempo real
- ✅ Historial de mensajes persistente (PostgreSQL)
- ✅ Con estatus online/offline
- ✅ Búsqueda de mensajes

### Opcionales (Implementadas)
- ✅ **Bloqueo de contactos** - Bidireccional con validación en creación de chats
- ✅ **Eliminación de mensajes** - Simple o en lote

## Requisitos

- Elixir >= 1.17
- Erlang/OTP >= 25
- Mix (incluido con Elixir)
- PostgreSQL (vía Ecto, necesario para persistencia de usuarios y mensajes)

## Inicio rapido

```bash
cd ..
make setup-docker         # agrega usuario a grupo docker
newgrp docker             # activa grupo sin relogin
make setup-dockerized     # levanta backend dockerizado
make docker-logs          # ver logs del backend

# Alternativa sin reiniciar sesión:
# make setup-docker && make setup-dockerized-sudo

# O si prefieres sin Docker:
# cd chat_app && mix run --no-halt
```

Nota: al iniciar, la app intenta correr migraciones automáticamente. Si vienes de una base vacía, los comandos anteriores se encargan de eso. Servidor disponible en:
- HTTP: http://localhost:4000
- WebSocket: ws://localhost:4000/ws?user=username

## Reiniciar la Base de Datos

Durante desarrollo, puedes querer limpiar la BD de test/pruebas previas:

```bash
# Opción 1: Comando rápido desde raíz
cd ..
make db-reset

# Opción 2: Manual desde chat_app
cd chat_app
mix ecto.drop
mix ecto.create
mix ecto.migrate
```

Después, reinicia el servidor `make dev` y tendrás una base de datos completamente limpia sin usuarios ni mensajes.

**Para preparar demo limpia**, usa:
```bash
make demo-setup    # Resetea BD + muestra instrucciones
```

## Docker (recomendado)

Este backend usa PostgreSQL para persistencia y en Docker se guarda en el volumen `postgres_data`.
Flujo recomendado:

```bash
cd ..
make setup-docker        # agrega usuario a grupo docker
newgrp docker            # activa grupo sin relogin
make setup-dockerized    # build + up + status
make docker-logs         # ver logs
make docker-down         # detener contenedores
```

**Si aparece `permission denied /var/run/docker.sock`:**
- Usa `newgrp docker` para activar el grupo sin relogin
- O usa los comandos con `-sudo`: `make setup-dockerized-sudo`, `make docker-logs-sudo`, etc.
- O ejecuta `make setup-docker`, cierra sesión y vuelve a entrar (solución permanente)

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

Mensajes soportados (JSON):
```json
{
  "action": "send_message",
  "chat_id": "chat_123",
  "msg_content": "Hola!"
}
```

### Acciones disponibles

#### Gestión de contactos
- `get_contacts` - Obtiene lista de contactos
- `add_contact` - Añade un nuevo contacto
- `block_contact` - Bloquea la comunicación con un usuario (bidireccional)

#### Gestión de chats
- `get_chatrooms` - Obtiene lista de chats
- `create_group_chat` - Crea chat grupal (rechaza si hay contactos bloqueados)
- `get_status` - Obtiene estado de usuarios

#### Manejo de mensajes
- `get_messages` - Obtiene historial de un chat
- `send_message` - Envía mensaje (falla si remitente está bloqueado)
- `delete_message` - Borra un mensaje por ID
- `delete_messages` - Borra múltiples mensajes

#### Búsqueda
- `search_messages` - Busca mensajes que contengan una palabra

#### Notificaciones offline
- Si el usuario está conectado, la notificación se entrega en tiempo real por WebSocket.
- Si el usuario está offline, la notificación se encola en `ActivityServer`.
- Si no existe `ActivityServer` para ese usuario, se inicia vía `ActivitySupervisor` antes de encolar.

## Consola interactiva (IEx)

```elixir
# Registrar usuarios
ChatApp.Accounts.register_user("alice", "pass123")
ChatApp.Accounts.register_user("bob", "pass456")

# Crear chat privado
{:ok, chat_id} = ChatApp.ChatManager.create_private_chat("alice", "bob")

# Enviar mensaje
msg = ChatApp.ChatRoomServer.add_message(chat_id, "alice", "Hola Bob!")

# Obtener mensajes
ChatApp.ChatRoomServer.get_messages(chat_id)

# Buscar mensajes
ChatApp.ChatRoomServer.search_messages(chat_id, "Hola")

# Bloquear contacto (bidireccional)
ChatApp.Accounts.block_contact("alice", "bob")

# Verificar si están bloqueados
ChatApp.Accounts.interaction_blocked?("alice", "bob")  # => true
ChatApp.Accounts.interaction_blocked?("bob", "alice")  # => true

# Borrar un mensaje
ChatApp.ChatRoomServer.delete_message(chat_id, "alice", msg.id)

# Borrar múltiples mensajes
ChatApp.ChatRoomServer.delete_messages(chat_id, "alice", [msg1.id, msg2.id])
```

## Modulos principales

- `ChatApp.Application` - Punto de entrada OTP y supervision
- `ChatApp.Accounts` - Registro y autenticacion de usuarios (con Ecto + PostgreSQL)
- `ChatApp.ChatManager` - Gestor central de conversaciones
- `ChatApp.ChatRoomServer` - Logica de salas y mensajes (con persistencia en PostgreSQL)
- `ChatApp.ActivityServer` - Estado activo/inactivo y cola offline por usuario
- `ChatApp.ActivitySupervisor` - Supervisor dinámico de ActivityServer
- `ChatApp.ChatRoomSupervisor` - Supervisor dinamico de salas
- `ChatApp.Repo` - Repositorio Ecto para PostgreSQL
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
Configurar en `config/config.exs`:
```elixir
config :chat_app, ChatApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  database: "chat_app_dev",
  pool_size: 10
```

## Desarrollo y testing

```bash
# Ejecutar todos los tests
mix test

# Con más detalles
mix test --trace

# Test específico
mix test test/accounts_test.exs

# Mostrar cobertura
mix test --cover

# Formatear código
mix format

# Compilar con warnings como errores
mix compile --warnings-as-errors

# Análisis estático
mix dialyzer
```

### Test Coverage

- Suite de tests cubriendo:
  - Autenticación y gestión de usuarios
  - Creación y gestión de chats (privados y grupales)
  - Mensajería y búsqueda
  - **Bloqueo de contactos (bidireccional)**
  - **Eliminación de mensajes (simple y lote)**
  - API WebSocket
  - Validaciones de schema

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
mix ecto.drop
mix ecto.create
mix ecto.migrate
```

## Enlaces útiles

### Documentación del Proyecto (nivel superior)
- [README principal](../README.md) - Visión general y características
- [DEMO.md](../DEMO.md) - Guía paso a paso para demostración en vivo
- [CLIENT_README.md](../CLIENT_README.md) - Documentación del cliente Python
- [COBERTURA_TESTS.md](../COBERTURA_TESTS.md) - Guía de cobertura de tests

### Documentación de Desarrollo
- [ARQUITECTURA.md](../ARQUITECTURA.md) - Decisiones de arquitectura y diagrama
- [DESARROLLO.md](../DESARROLLO.md) - Lineamientos de desarrollo
- [ESTADO.md](../ESTADO.md) - Resumen de features implementados vs pendientes
- [consigna-tp-final.txt](../consigna-tp-final.txt) - Enunciado original del trabajo

