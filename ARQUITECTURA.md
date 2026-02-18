# Arquitectura del Sistema

## Stack

- Backend: Elixir + OTP
- Transporte: WebSocket (Cowboy) + REST mínimo
- Persistencia: PostgreSQL + Ecto
- Cache/estado en memoria: ETS + procesos OTP

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
├── Registry.UsersRegistry
├── Registry.ChatRoomsRegistry
├── Registry.ActivityRegistry
├── ChatApp.ActivitySupervisor (DynamicSupervisor)
│   └── ChatApp.ActivityServer (1 por usuario)
├── ChatApp.ChatRoomSupervisor (DynamicSupervisor)
│   └── ChatApp.ChatRoomServer (1 por chat)
└── Plug.Cowboy (HTTP + WS)
```

## Flujos clave

### 1) Registro/Login

1. Cliente llama `POST /api/register` o `POST /api/login`
2. `Accounts` valida y persiste/consulta usuarios en PostgreSQL
3. Cliente conecta WebSocket con `?user=username`

### 2) Mensaje en tiempo real

1. Cliente envía acción `send_message`
2. `SocketHandler` valida payload
3. `ChatRoomServer` persiste y distribuye notificaciones
4. Receptores online reciben inmediatamente

### 3) Notificaciones offline

1. Si receptor está offline, `ActivityServer` encola evento
2. Al reconectar, el servidor entrega pendientes automáticamente

### 4) Envío de archivos

1. Cliente envía `send_file` con contenido Base64
2. `FileManager` valida MIME y tamaño (máx 5MB), guarda en `priv/uploads`
3. Mensaje persiste metadatos de archivo
4. Descarga por `GET /uploads/:filename`

## Decisiones de diseño

- **Proceso por usuario/sala**: simplifica aislamiento de estado y tolerancia a fallos.
- **Persistencia completa**: evita pérdida de historial tras reinicio.
- **Base64 en WS para adjuntos**: compatible con cliente consola y web.
- **Borrado con cleanup físico**: elimina archivo del disco al borrar mensaje.

## Escalabilidad y límites

- Límite actual de adjuntos: 5MB por mensaje
- Backups de mensajes: implementados en modo manual (pg_dump/pg_restore)
