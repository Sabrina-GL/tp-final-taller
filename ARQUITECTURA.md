# Arquitectura del Sistema

## Stack

- Backend: Elixir + OTP
- Transporte: WebSocket (Cowboy) + REST mínimo
- Persistencia: PostgreSQL + Ecto
- Estado en memoria: procesos OTP + Registros (`Registry`)

## Componentes principales

- `ChatWeb.Router`: endpoints HTTP y upgrade a WebSocket
- `ChatWeb.SocketHandler`: protocolo WS (acciones JSON)
- `ChatApp.Accounts`: registro, autenticación, contactos/bloqueos
- `ChatApp.ChatManager`: orquestación de chats
- `ChatApp.ChatRoomServer`: mensajes por sala
- `ChatApp.ActivityServer`: estado online/offline + cola offline por usuario
- `ChatApp.FileManager`: validación y almacenamiento de adjuntos
- `ChatApp.Repo`: acceso a PostgreSQL

## Topología OTP

```text
ChatApp.Application
├── ChatApp.Repo
├── Registry.UsersRegistry
├── Registry.ChatRoomsRegistry
├── Registry.ActivityRegistry
├── ChatApp.ActivitySupervisor (DynamicSupervisor)
│   └── ChatApp.ActivityServer (1 por usuario)
├── ChatApp.ChatRoomSupervisor (DynamicSupervisor)
│   └── ChatApp.ChatRoomServer (1 por chat)
└── Plug.Cowboy (HTTP + WS)
```

Nota: en arranque también se ejecutan migraciones automáticas (si están habilitadas en configuración).

## Flujos clave

### 1) Registro/Login

1. Cliente llama `POST /api/register` o `POST /api/login`
2. `Accounts` valida y persiste/consulta usuarios en PostgreSQL
3. Backend devuelve `token` firmado
4. Cliente conecta WebSocket con `?token=<token>`

### 2) Mensaje en tiempo real

1. Cliente envía acción `send_message`
2. `SocketHandler` valida payload
3. `ChatRoomServer` persiste y distribuye notificaciones
4. Receptores online reciben inmediatamente

### 3) Notificaciones offline

1. `Notifications` intenta entregar en vivo por `UsersRegistry`
2. Si receptor está offline, persiste pendiente en `ActivityServer`
3. Al reconectar, `SocketHandler` solicita pendientes y los entrega automáticamente

### 4) Envío de archivos

1. Cliente envía `send_file` con contenido Base64
2. `FileManager` valida MIME y tamaño (máx 5MB), guarda en `priv/uploads`
3. Mensaje persiste metadatos de archivo
4. Descarga por `GET /uploads/:filename`

## Decisiones de diseño

- **Proceso por usuario/sala**: simplifica aislamiento de estado y tolerancia a fallos.
- **Persistencia en DB + ventana en memoria**: los mensajes se persisten en PostgreSQL y cada `ChatRoomServer` opera con una ventana reciente (últimos 10) para consultas rápidas.
- **Base64 en WS para adjuntos**: compatible con cliente consola y web.
- **Borrado con cleanup físico**: elimina archivo del disco al borrar mensaje.

## Escalabilidad y límites

- Límite actual de adjuntos: 5MB por mensaje
- Backups de mensajes: implementados en modo manual (pg_dump/pg_restore)
