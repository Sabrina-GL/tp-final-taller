# Arquitectura del Sistema de Chat

## Visión General

El sistema está construido con **Elixir + OTP** para máxima confiabilidad y concurrencia. Utiliza patrones de supervivencia automática y comunicación basada en actores.

```
┌─────────────────────────────────────────────────────────┐
│                   Clientes Web/CLI                      │
│            (WebSocket + REST API)                       │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
    HTTP/REST              WebSocket
        │                         │
        │    ┌────────────────────┴──────┐
        │    │                           │
        ▼    ▼                           ▼
┌──────────────────────────────────────────────────┐
│      ChatWeb.Router (Plug + Cowboy)              │
│  - GET /register, /login, /index                 │
│  - POST /api/register, /api/login                │
│  - GET /ws?user=usuario (upgrade WebSocket)      │
└──────────────────┬───────────────────────────────┘
                   │
                   ▼
       ┌─────────────────────────────┐
       │   ChatWeb.SocketHandler     │
       │  (Manejo de WebSocket)      │
       │  - websocket_init/1         │
       │  - websocket_handle/2       │
       │  - websocket_info/2         │
       └────────────┬────────────────┘
                    │
    ┌───────────────┼───────────────┐
    │               │               │
    ▼               ▼               ▼
ChatApp.Accounts ChatManager Activity
 (GenServer)    (GenServer)  Tracker
    │               │        (GenServer)
    │         ┌─────┴─────┐       │
    │         │           │       │
    │         ▼           ▼       │
    │    ChatRoomSuper   ChatRoom │
    │    visor (Dyn)    (Dyn x N) │
    │                             │
    └─────────────┬───────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
   Registry            State
 (UsersRegistry)     (In-Memory)
```

## Componentes Principales

### 1. **ChatWeb.Router** (HTTP Gateway)
- **Rol**: Punto de entrada HTTP y WebSocket
- **Responsabilidades**:
  - Servir archivos estáticos (HTML, CSS, JS)
  - Rutas de registro y login
  - Upgrade a WebSocket
- **Ejemplo**:
  ```elixir
  get "/register" do
    send_file(conn, 200, "priv/static/register.html")
  end
  ```

### 2. **ChatWeb.SocketHandler** (WebSocket Manager)
- **Rol**: Maneja conexiones WebSocket individuales
- **Responsabilidades**:
  - Procesar mensajes del cliente
  - Mantener estado de la conexión
  - Comunicarse con ChatManager
- **Callbacks OTP**:
  - `websocket_init/1`: Inicialización de conexión
  - `websocket_handle/2`: Procesar mensajes entrantes
  - `websocket_info/2`: Procesar mensajes desde otros procesos

### 3. **ChatApp.Accounts** (GenServer)
- **Rol**: Almacén central de usuarios
- **Responsabilidades**:
  - Registro de usuarios
  - Autenticación
  - Gestión de contactos
  - Validación de credenciales
- **Estado**:
  ```elixir
  %{
    "alice" => %{password: hash, contacts: ["bob"], chat_rooms: [...]},
    "bob" => %{password: hash, contacts: ["alice"], chat_rooms: [...]},
    ...
  }
  ```

### 4. **ChatApp.ChatManager** (GenServer)
- **Rol**: Orquestador de conversaciones
- **Responsabilidades**:
  - Crear salas de chat (dinámicamente)
  - Enrutar mensajes
  - Mantener historial global (opcional)
  - Gestionar el ciclo de vida de las salas
- **Estado**:
  ```elixir
  %{
    "alice:bob" => ChatApp.ChatRoom(pid),
    "group:project" => ChatApp.ChatRoom(pid),
    ...
  }
  ```

### 5. **ChatApp.ChatRoom** (GenServer Dinámico)
- **Rol**: Lógica de una sala individual
- **Responsabilidades**:
  - Almacenar últimos 10 mensajes
  - Búsqueda de mensajes
  - Gestión de participantes
- **Estado**:
  ```elixir
  %{
    id: "alice:bob",
    participants: ["alice", "bob"],
    messages: [
      %{from: "alice", msg_content: "Hola", timestamp: ~U[...]},
      %{from: "bob", msg_content: "Hola Alice", timestamp: ~U[...]}
    ]
  }
  ```

### 6. **ChatApp.ChatRoomSupervisor** (DynamicSupervisor)
- **Rol**: Gestor del ciclo de vida de salas
- **Responsabilidades**:
  - Crear nueva sala cuando se necesita
  - Supervisar salas activas
  - Reiniciar salas si fallan
  - Limpiar salas vacías (futuro)

### 7. **ChatApp.ActivityTracker** (GenServer)
- **Rol**: Rastreo de actividad
- **Responsabilidades**:
  - Registrar cuándo usuarios están online/offline
  - Guardar timestamp de última actividad
  - Mantener lista de usuarios activos
- **Estado**:
  ```elixir
  %{
    "alice" => %{status: :online, last_seen: ~U[...]},
    "bob" => %{status: :offline, last_seen: ~U[...]}
  }
  ```

### 8. **Registry** (Elixir Built-in)
- **Rol**: Directorio de procesos
- **Uso**: 
  - Mapear nombres de usuarios a PIDs de conexión
  - Permitir broadcast rápido a usuarios específicos
- **Ejemplo**:
  ```elixir
  Registry.register(ChatApp.UsersRegistry, "alice", :connected)
  {:ok, _} = Registry.lookup(ChatApp.UsersRegistry, "alice")
  ```

## Flujos de Datos

### Flujo 1: Registro de Usuario

```
Usuario relena formulario
  ↓
POST /api/register con {username, password}
  ↓
ChatWeb.Router.post("/api/register")
  ↓
ChatApp.Accounts.register_user(username, password)
  ↓
Almacenar en estado del GenServer
  ↓
Responder al cliente
```

### Flujo 2: Envío de Mensaje

```
Cliente envía JSON por WebSocket
  │
  ├─ {"action": "send_message", "chat_id": "...", "msg_content": "..."}
  │
  ▼
ChatWeb.SocketHandler.websocket_handle/2
  ├─ Parse JSON
  ├─ Validar usuario
  │
  ▼
ChatApp.ChatRoom.add_message(chat_id, user, msg_content)
  │
  ├─ Obtener ChatRoom pid
  │
  ▼
ChatApp.ChatRoom.add_message/1
  ├─ Agregar a historial (max 10)
  │
  ▼
Broadcast a todos los participantes
  ├─ Via Registry.dispatch para usuarios online
  │
  ▼
Cada cliente recibe {:text, json_response}
```

### Flujo 3: Búsqueda de Mensajes

```
Cliente solicita búsqueda
  ↓
ChatApp.ChatManager.search_messages(chat_id, keyword)
  ↓
Obtener ChatRoom pid
  ↓
ChatApp.ChatRoom.search/2
  ├─ Enumerar histórico
  ├─ Filtrar por keyword
  │
  ▼
Retornar resultados al cliente
```

### Flujo 4: Rastreo de Actividad

```
Conexión WebSocket establecida
  ↓
ChatApp.ActivityTracker.user_online(username)
  ├─ Actualizar estado a :online
  ├─ Registrar en Registry
  │
  ▼
Usuario inactivo 5 min
  ↓
ChatApp.ActivityTracker.user_offline(username)
  ├─ Cambiar estado a :offline
  ├─ Desregistrar del Registry
  │
  ▼
Notificar a contactos (futuro)
```

## Patrones OTP Utilizados

### 1. **Supervisor Pattern**
```elixir
# ChatApp.Application
children = [
  {Registry, keys: :unique, name: ChatApp.UsersRegistry},
  ChatApp.Accounts,
  ChatApp.ChatManager,
  ChatApp.ActivityTracker,
  ChatApp.ChatRoomSupervisor,
  Plug.Cowboy.child_spec(...)
]
Supervisor.start_link(children, strategy: :one_for_one)
```

**Estrategia**: `one_for_one`
- Si un servicio falla, solo se reinicia ese servicio
- Los demás continúan operando

### 2. **GenServer Pattern**
```elixir
# Para Accounts, ChatManager, ActivityTracker
def init(initial_state) do
  {:ok, initial_state}
end

def handle_call({:register, user, pass}, _from, state) do
  {:reply, :ok, new_state}
end

def handle_cast({:user_online, user}, state) do
  {:noreply, new_state}
end
```

### 3. **Dynamic Supervisor Pattern**
```elixir
# Para ChatRoomSupervisor
def start_link(_init_arg) do
  DynamicSupervisor.start_link(
    strategy: :one_for_one,
    name: ChatApp.ChatRoomSupervisor
  )
end

def start_child(chat_id, participants) do
  DynamicSupervisor.start_child(
    __MODULE__,
    {ChatApp.ChatRoom, {chat_id, participants}}
  )
end
```

### 4. **Registry Pattern**
```elixir
# Para búsqueda eficiente de usuarios online
Registry.register(registry, key, value)
Registry.lookup(registry, key)
Registry.dispatch(registry, key, callback_fn)
```

## Escalabilidad

### Actual (In-Memory)
- ✅ Funciona para ~100-1000 usuarios simultáneos
- ✅ Bajo latency
- ❌ Pérdida de datos al reiniciar
- ❌ No distribuido

### Mejoras Futuras
1. **Persistencia**: Ecto + SQLite/PostgreSQL
2. **Distribución**: Erlang clustering
3. **Cache**: Redis para sesiones
4. **Message Queue**: Para tolerancia a fallos
5. **Load Balancing**: Múltiples nodos

## Seguridad

### Actual
- ✅ Contraseñas hasheadas (bcrypt_elixir)
- ✅ Validación de entrada
- ❌ Sin HTTPS
- ❌ Sin rate limiting
- ❌ Sin autorización granular

### Mejoras
- [ ] HTTPS/WSS
- [ ] Rate limiting
- [ ] JWT tokens
- [ ] Input sanitization
- [ ] CORS configuration

## Testing Strategy

```
┌──────────────────────────────────────────┐
│         Unit Tests (80% cobertura)       │
│  - Cada función probada aisladamente     │
│  - Mocks de dependencias                 │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│      Integration Tests (60% cobertura)   │
│  - Flujos completos (registro → mensaje) │
│  - GenServers trabajando juntos          │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│        End-to-End Tests (Manual)         │
│  - Cliente real → Servidor → Cliente     │
│  - WebSocket real                        │
└──────────────────────────────────────────┘
```

## Monitoreo y Observabilidad

```elixir
# Ver procesos activos
:observer.start()

# Estado de GenServer
:sys.get_state(ChatApp.Accounts)

# Trace de llamadas
:sys.trace(ChatApp.ChatManager, true)

# Stats del sistema
:erlang.statistics(:run_queue)
```

## Resumen

| Componente | Tipo | Propósito | Escala |
|-----------|------|---------|--------|
| Router | Plug | Gateway HTTP | Stateless |
| SocketHandler | - | Conexión WS | Por cliente |
| Accounts | GenServer | Gestión usuarios | 1 proceso |
| ChatManager | GenServer | Orquestación | 1 proceso |
| ChatRoom | GenServer | Lógica sala | N procesos |
| ActivityTracker | GenServer | Actividad | 1 proceso |
| ChatRoomSupervisor | DynamicSupervisor | Supervisor | 1 proceso |
| Registry | Built-in | Directorio | Built-in |

