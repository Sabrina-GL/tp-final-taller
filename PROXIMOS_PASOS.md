# Próximos Pasos - Sistema de Chat

## 🚀 Comenzar a Desarrollar

### Paso 1: Verificar Instalación
```bash
cd chat_app
mix deps.get
mix compile
```

### Paso 2: Ejecutar el Servidor
```bash
iex -S mix
```

Deberías ver:
```
Erlang/OTP 25 [erts-13.0] ...
Interactive Elixir (1.17.0) ...
iex(1)>
```

### Paso 3: Probar Desde IEx
```elixir
# Registrar usuarios de prueba
ChatApp.Accounts.register_user("alice", "pass123")
ChatApp.Accounts.register_user("bob", "pass456")

# Verificar que se registraron
:sys.get_state(ChatApp.Accounts)
```

### Paso 4: Probar el Web
1. Abrir navegador en `http://localhost:4000`
2. Deberías ver la página de registro
3. Crear usuario desde el formulario

## 📝 Orden de Implementación Sugerido

### Semana 1: Core Features Básicos
1. **Completar ChatApp.Accounts**
   - Validación de usuarios
   - Hash de passwords
   - Gestión de contactos
   
2. **Mejorar ChatApp.ChatManager**
   - Crear chats directos
   - Enrutar mensajes
   - Mantener registro de chats

3. **Implementar ChatApp.ChatRoom**
   - Almacenar mensajes (límite 10)
   - Broadcast a participantes
   - Búsqueda básica

### Semana 2: WebSocket y Actividad
4. **Completar ChatWeb.SocketHandler**
   - Parse de mensajes JSON
   - Envío de mensajes
   - Recepción de mensajes

5. **Mejorar ChatApp.ActivityTracker**
   - Rastreo de online/offline
   - Timestamps de actividad
   - Integración con Registry

6. **Tests Básicos**
   - Tests de Accounts
   - Tests de ChatManager
   - Tests de ChatRoom

### Semana 3: Features Avanzados
7. **Chats Grupales**
   - Crear grupos
   - Agregar/remover participantes
   - Mensajes grupales

8. **Notificaciones**
   - Mensajes pendientes
   - Mostrar al reconectar
   - API de notificaciones

9. **Front-end Mejorado**
   - JavaScript funcional
   - CSS responsive
   - UX mejorado

### Semana 4: Pulido y Entrega
10. **Features Opcionales** (elegir 1-2)
    - Envío de archivos
    - Bloquear contactos
    - Borrar mensajes
    - Backups

11. **Testing Exhaustivo**
    - Coverage >80%
    - Tests de integración
    - Tests de concurrencia

12. **Documentación Final**
    - README completo
    - ExDoc generado
    - Video demo (opcional)

## 🔧 Implementación Detallada

### Feature: Alta de Usuarios

#### 1. En `lib/chat_app/accounts.ex`:

```elixir
defmodule ChatApp.Accounts do
  use GenServer

  # Client API
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_user(username, password) do
    GenServer.call(__MODULE__, {:register, username, password})
  end

  def authenticate_user(username, password) do
    GenServer.call(__MODULE__, {:authenticate, username, password})
  end

  # Server Callbacks
  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:register, username, password}, _from, state) do
    cond do
      String.length(username) < 3 ->
        {:reply, {:error, "Username too short"}, state}
      
      Map.has_key?(state, username) ->
        {:reply, {:error, "Username already exists"}, state}
      
      String.length(password) < 6 ->
        {:reply, {:error, "Password too short"}, state}
      
      true ->
        hashed = Bcrypt.hash_pwd_salt(password)
        new_state = Map.put(state, username, %{
          password: hashed,
          contacts: [],
          blocked: []
        })
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:authenticate, username, password}, _from, state) do
    case Map.get(state, username) do
      nil ->
        {:reply, {:error, "User not found"}, state}
      
      user_data ->
        if Bcrypt.verify_pass(password, user_data.password) do
          {:reply, :ok, state}
        else
          {:reply, {:error, "Invalid password"}, state}
        end
    end
  end
end
```

#### 2. Test en `test/chat_app_test.exs`:

```elixir
test "register user successfully" do
  assert :ok = ChatApp.Accounts.register_user("testuser", "password123")
end

test "reject duplicate username" do
  ChatApp.Accounts.register_user("duplicate", "pass1")
  assert {:error, _} = ChatApp.Accounts.register_user("duplicate", "pass2")
end

test "authenticate with correct password" do
  ChatApp.Accounts.register_user("authuser", "correctpass")
  assert :ok = ChatApp.Accounts.authenticate_user("authuser", "correctpass")
end

test "reject wrong password" do
  ChatApp.Accounts.register_user("authuser2", "correctpass")
  assert {:error, _} = ChatApp.Accounts.authenticate_user("authuser2", "wrongpass")
end
```

#### 3. Ejecutar tests:
```bash
mix test
```

### Feature: Envío de Mensajes

#### 1. En `lib/chat_app/chat_manager.ex`:

```elixir
def send_message(chat_id, from_user, content) do
  GenServer.call(__MODULE__, {:send_message, chat_id, from_user, content})
end

@impl true
def handle_call({:send_message, chat_id, from_user, content}, _from, state) do
  case Map.get(state, chat_id) do
    nil ->
      {:reply, {:error, "Chat not found"}, state}
    
    room_pid ->
      message = %{
        from: from_user,
        content: content,
        timestamp: DateTime.utc_now()
      }
      
      ChatApp.ChatRoom.add_message(room_pid, message)
      
      # Broadcast a todos los participantes
      ChatApp.ChatRoom.get_participants(room_pid)
      |> Enum.each(fn participant ->
        send_to_user(participant, {:new_message, chat_id, message})
      end)
      
      {:reply, :ok, state}
  end
end

defp send_to_user(username, message) do
  case Registry.lookup(ChatApp.UsersOnlineRegistry, username) do
    [{pid, _}] -> send(pid, message)
    [] -> :ok  # Usuario offline
  end
end
```

#### 2. En `lib/chat_app/chat_room.ex`:

```elixir
defmodule ChatApp.ChatRoom do
  use GenServer

  def start_link({chat_id, participants}) do
    GenServer.start_link(__MODULE__, {chat_id, participants})
  end

  def add_message(room_pid, message) do
    GenServer.cast(room_pid, {:add_message, message})
  end

  def get_messages(room_pid, limit \\ 10) do
    GenServer.call(room_pid, {:get_messages, limit})
  end

  @impl true
  def init({chat_id, participants}) do
    state = %{
      id: chat_id,
      participants: participants,
      messages: []
    }
    {:ok, state}
  end

  @impl true
  def handle_cast({:add_message, message}, state) do
    new_messages = [message | state.messages] |> Enum.take(10)
    {:noreply, %{state | messages: new_messages}}
  end

  @impl true
  def handle_call({:get_messages, limit}, _from, state) do
    messages = Enum.take(state.messages, limit)
    {:reply, messages, state}
  end
end
```

### Feature: WebSocket Funcional

#### 1. En `lib/chat_web/socket_handler.ex`:

```elixir
def websocket_handle({:text, msg}, state) do
  case Jason.decode(msg) do
    {:ok, data} ->
      handle_message(data, state)
    
    {:error, _} ->
      reply = Jason.encode!(%{error: "Invalid JSON"})
      {:reply, {:text, reply}, state}
  end
end

defp handle_message(%{"type" => "message", "chat_id" => chat_id, "content" => content}, state) do
  case ChatApp.ChatManager.send_message(chat_id, state.user, content) do
    :ok ->
      {:ok, state}
    
    {:error, reason} ->
      reply = Jason.encode!(%{error: reason})
      {:reply, {:text, reply}, state}
  end
end

defp handle_message(%{"type" => "get_messages", "chat_id" => chat_id}, state) do
  messages = ChatApp.ChatManager.get_messages(chat_id, 10)
  reply = Jason.encode!(%{type: "messages", data: messages})
  {:reply, {:text, reply}, state}
end

# Recibir mensajes desde otros procesos
def websocket_info({:new_message, chat_id, message}, state) do
  reply = Jason.encode!(%{
    type: "new_message",
    chat_id: chat_id,
    message: message
  })
  {:reply, {:text, reply}, state}
end
```

## 🧪 Testing Continuo

Después de implementar cada feature:

```bash
# Ejecutar tests
mix test

# Con cobertura
mix test --cover

# Formatear código
mix format

# Ver warnings
mix compile --warnings-as-errors
```

## 📚 Recursos Útiles

### Documentación Oficial
- [Elixir Lang](https://elixir-lang.org/docs.html)
- [Erlang/OTP](https://erlang.org/doc/)
- [Cowboy](https://ninenines.eu/docs/)
- [Plug](https://hexdocs.pm/plug/)

### Tutoriales
- [ElixirSchool](https://elixirschool.com/)
- [Phoenix WebSocket](https://hexdocs.pm/phoenix/channels.html)
- [OTP Basics](https://elixir-lang.org/getting-started/mix-otp/supervisor-and-application.html)

### Herramientas
- [ElixirLS](https://github.com/elixir-lsp/elixir-ls) - VS Code extension
- [Observer](http://erlang.org/doc/apps/observer/observer_ug.html) - `:observer.start()`
- [Credo](https://github.com/rrrene/credo) - Linter

## 💡 Tips de Desarrollo

### 1. Usar IEx para Debugging
```elixir
# En iex -S mix
require IEx
IEx.pry()  # Breakpoint

# Ver estado de GenServer
:sys.get_state(ChatApp.Accounts)

# Trace de procesos
:sys.trace(ChatApp.ChatManager, true)
```

### 2. Hot Reload
El código se recarga automáticamente en `iex -S mix`. Si haces cambios:
```elixir
recompile()
```

### 3. Logs
```elixir
require Logger
Logger.info("Usuario conectado: #{user}")
Logger.error("Error: #{inspect(error)}")
```

### 4. Testing Específico
```bash
# Un test específico
mix test test/chat_app_test.exs:10

# Con output detallado
mix test --trace
```

## 🎯 Objetivos Semanales

### Semana 1 ✅
- [x] Configuración completa
- [ ] Accounts funcional
- [ ] Tests de Accounts

### Semana 2 ⏳
- [ ] ChatManager funcional
- [ ] ChatRoom funcional
- [ ] WebSocket básico

### Semana 3 ⏳
- [ ] Chats grupales
- [ ] Notificaciones
- [ ] Front-end mejorado

### Semana 4 ⏳
- [ ] Features opcionales
- [ ] Testing exhaustivo
- [ ] Demo lista

## 📞 Ayuda

Si tienes dudas:
1. Revisar ARQUITECTURA.md para entender el diseño
2. Revisar DESARROLLO.md para ejemplos
3. Consultar documentación oficial
4. Usar `:observer.start()` para debugging
5. Preguntar en el repositorio (Issues)

---

**¡Éxito con el desarrollo!** 🚀
