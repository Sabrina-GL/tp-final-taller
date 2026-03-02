# Flujo de la aplicación (con actores)

Este documento explica cómo funciona la app de chat de punta a punta, con un ejemplo concreto (registro/login → conexión WebSocket → envío de mensaje) y qué actor participa en cada etapa.

## 1) Actores del sistema

### Actores externos
- **Usuario Web**: usa `register.html`, `login.html` e `index.html`.
- **Cliente Python (CLI)**: usa `client.py` y habla con la misma API HTTP/WS.

### Actores de borde (entrada/salida)
- **`ChatWeb.Router`**: recibe HTTP, sirve estáticos, maneja `/api/register`, `/api/login`, `/ws`, `/uploads/:filename`.
- **`ChatWeb.SocketHandler`**: proceso WebSocket por conexión; decodifica acciones (`action`) y responde en tiempo real.

### Actores de dominio
- **`ChatApp.Accounts`**: registro/autenticación, contactos, bloqueos, `last_seen`.
- **`ChatApp.ChatManager`**: crea chats privados/grupales, lista chats de usuario, garantiza que procesos de sala estén activos.
- **`ChatApp.ChatRoomServer`**: GenServer por chatroom; persiste/recupera mensajes, valida permisos y bloqueos, notifica nuevos mensajes.
- **`ChatApp.ActivityServer`**: presencia por usuario (online/offline, última actividad).
- **`ChatApp.Notifications`**: envíos asíncronos (nuevo chat, nuevo mensaje, contacto agregado, etc.).
- **`ChatApp.FileManager`**: guarda y elimina archivos adjuntos.

### Actores de infraestructura OTP
- **`ChatApp.Application`**: arranque principal; levanta árbol de supervisión.
- **`ChatApp.Supervisor`** (`one_for_one`): supervisor raíz.
- **`ChatApp.ActivitySupervisor`** (`DynamicSupervisor`): crea un `ActivityServer` por usuario conectado.
- **`ChatApp.ChatRoomSupervisor`** (`DynamicSupervisor`): crea un `ChatRoomServer` por sala de chat.
- **`Registry`**:
  - `ChatApp.UsersRegistry`: mapea usuario → PID de conexión WS.
  - `ChatApp.ChatRoomsRegistry`: mapea `chat_id` → PID del `ChatRoomServer`.
  - `ChatApp.ActivityRegistry`: mapea usuario → PID de presencia.
- **`ChatApp.Repo`**: acceso a PostgreSQL (Ecto).
- **`Plug.Cowboy`**: servidor HTTP/WS.

## 2) Flujo ejemplo: Alice le manda "hola" a Bob

## Paso A — Registro e inicio de sesión
1. Alice hace `POST /api/register`.
2. `ChatWeb.Router` llama `Accounts.register_user/2`.
3. Si sale bien, el router genera token con `AuthToken.issue_token/1` y responde JSON.
4. Luego Alice hace `POST /api/login`.
5. `ChatWeb.Router` llama `Accounts.authenticate_user/2` y devuelve token.

> Bob repite el mismo flujo.

## Paso B — Apertura de WebSocket autenticado
1. Alice conecta a `GET /ws?token=...`.
2. `ChatWeb.Router` valida token con `AuthToken.verify_token/1` y hace upgrade a WebSocket con `ChatWeb.SocketHandler`.
3. En `SocketHandler.websocket_init/1`:
   - registra la conexión en `UsersRegistry`,
   - arranca presencia con `ActivitySupervisor.start_activity_server/1`,
   - marca online con `ActivityServer.user_online/1`,
   - entrega notificaciones pendientes (si existen).

> Bob también queda con su conexión WS y presencia activa.

## Paso C — Crear/obtener chat privado
1. Alice agrega a Bob como contacto (acción WS `add_contact`) o abre chat existente.
2. `SocketHandler` delega en `Accounts.add_contact/2` y `ChatManager.create_private_chat/2`.
3. `ChatManager`:
   - valida usuarios y bloqueos,
   - crea la chatroom en DB si no existe,
   - asegura proceso de sala con `ChatRoomSupervisor.start_chatroom/1`.

Resultado: existe un `chat_id` privado estable (ordenado por nombre de usuarios).

## Paso D — Envío del mensaje
1. Alice envía acción WS:
   - `action: "send_message"`
   - `chat_id: "alice:bob"`
   - `msg_content: "hola"`
2. `SocketHandler` llama `ChatRoomServer.add_message/3`.
3. En `ChatRoomServer.handle_call({:add_message, ...})`:
   - verifica que Alice sea participante,
   - verifica existencia/estado del usuario,
   - verifica bloqueos (`Accounts.blocked_with_any?/2`),
   - persiste en DB vía `Repo.insert(...)`,
   - serializa timestamp ISO-8601 UTC,
   - actualiza estado interno de la sala,
   - notifica a participantes con `Notifications.notify_new_message/3`.
4. Si Bob está conectado, su proceso WS recibe evento `{:new_message, chat_id, message}` y el frontend lo renderiza.

## Paso E — Presencia y privacidad
- Cuando un usuario se conecta/desconecta, `ActivityServer` actualiza estado y puede notificar contactos.
- La app filtra visibilidad de presencia si hay bloqueo entre usuarios (no se expone online/last_seen en esos casos).

## 3) Rol de los supervisores en este flujo

- **Supervisor raíz (`ChatApp.Supervisor`)**
  - Si cae un hijo (ej. `Plug.Cowboy` o `Repo`), aplica estrategia `one_for_one` y reinicia solo ese proceso.

- **`ActivitySupervisor` (dinámico)**
  - Aísla la presencia por usuario.
  - Si falla el proceso de actividad de Alice, se reinicia ese proceso sin afectar chats ni otras sesiones.

- **`ChatRoomSupervisor` (dinámico)**
  - Aísla cada sala (`chat_id`) en su propio GenServer.
  - Si falla la sala `alice:bob`, se recupera esa sala sin tumbar otras.

En términos prácticos: la arquitectura OTP evita un "fallo global" y limita errores al proceso específico.

## 4) Mapa rápido acción → módulo

- `POST /api/register` → `ChatWeb.Router` → `Accounts.register_user/2`
- `POST /api/login` → `ChatWeb.Router` → `Accounts.authenticate_user/2`
- `GET /ws?token=...` → `ChatWeb.Router` + `AuthToken.verify_token/1` → `ChatWeb.SocketHandler`
- `action: get_contacts` → `SocketHandler` → `Accounts.get_contacts/1`
- `action: add_contact` → `SocketHandler` → `Accounts.add_contact/2` + `ChatManager.create_private_chat/2`
- `action: send_message` → `SocketHandler` → `ChatRoomServer.add_message/3`
- `action: send_file` → `SocketHandler` → `ChatRoomServer.add_message/4` (+ `FileManager`)

## 5) Resumen conceptual

1. HTTP resuelve identidad (registro/login + token).
2. WebSocket mantiene sesión viva en tiempo real.
3. `SocketHandler` enruta acciones al dominio.
4. `ChatRoomServer` y `ActivityServer` contienen estado vivo por entidad (sala/usuario).
5. Supervisores dinámicos garantizan aislamiento y recuperación automática.
6. `Repo` conserva estado persistente (usuarios, contactos, salas, mensajes).
