# Cliente por Consola - Chat Application

Cliente interactivo en Python que se conecta al servidor Elixir vía WebSocket.

## 📋 Requisitos

- Python 3.7 o superior
- Servidor Elixir ejecutándose en `http://localhost:4000`

## 🚀 Instalación

1. Instalar dependencias:
```bash
pip install -r requirements.txt
```

O manualmente:
```bash
pip install websocket-client requests
```

## ▶️ Ejecución

1. **Backend Docker (recomendado)**

```bash
cd tp-final-taller
make setup-docker          # agrega usuario a grupo docker
newgrp docker              # activa grupo sin relogin
make setup-dockerized      # levanta backend en contenedor
```

**Alternativa sin reiniciar sesión:**
```bash
make setup-docker
make setup-dockerized-sudo # usa sudo directamente
```

2. **Ejecutar el cliente** (en otra terminal):

```bash
cd tp-final-taller
python3 client.py
```

3. **Alternativa local (sin Docker)**

```bash
cd chat_app
mix deps.get
mix ecto.create
mix ecto.migrate
iex -S mix
```

O hacerlo ejecutable:
```bash
chmod +x client.py
./client.py
```

## 🎮 Uso

### Pantalla Inicial
Al iniciar verás:
```
1. Registrarse
2. Iniciar sesión
3. Salir
```

### Registro
- Usuario: mínimo 3 caracteres
- Contraseña: mínimo 6 caracteres

### Menú Principal (después de login)
```
1. Ver contactos              → Muestra tu lista de contactos
2. Agregar contacto           → Agrega un usuario a tu lista
3. Bloquear contacto          → Bloquea la comunicación con un usuario (bidireccional)
4. Ver chats                  → Lista todos tus chats (1-a-1 y grupales)
5. Crear chat grupal          → Crea un nuevo grupo
6. Enviar mensaje             → Envía mensaje a un chat
7. Ver mensajes de un chat    → Obtiene últimos 10 mensajes
8. Buscar mensajes            → Busca por palabra clave en un chat
9. Eliminar un mensaje        → Borra un mensaje por ID
10. Eliminar múltiples mensajes → Borra varios mensajes de una vez
11. Ver estado de un usuario  → Muestra online/offline/last_seen
12. Salir                     → Cierra sesión
```

## 📝 Ejemplos de Uso

### 1. Registrar usuario
```
Seleccione una opción: 1
Usuario (mínimo 3 caracteres): alice
Contraseña (mínimo 6 caracteres): alice123
✅ Usuario 'alice' registrado exitosamente
```

### 2. Iniciar sesión
```
Seleccione una opción: 2
ID del chat: alice:bob
Contraseña: alice123
✅ Login exitoso. Bienvenido alice!
```

### 3. Agregar contacto
```
ID del chat: alice:bob
Usuario a agregar: bob
👤 Agregando contacto: bob
```

### 3b. Bloquear contacto
```
Opción: 3
Usuario a bloquear: charlie
🚫 Bloqueando a: charlie
```
*Nota: El bloqueo es bidireccional. Charlie tampoco podrá enviarte mensajes.*

### 4. Crear chat grupal
ID del chat: alice:bob
Opción: 4
Nombre del grupo: equipo
Participantes (separados por coma): bob, charlie
👥 Creando chat grupal: equipo
```

### 6. Ver mensajes
```
Opción: 6
ID del chat: alice:bob
📬 Obteniendo mensajes de alice:bob...
```

### 7. Buscar mensajes
```
Opción: 8
ID del chat: alice:bob
Palabra clave a buscar: reunión
🔍 Buscando 'reunión' en alice:bob...
```

### 8. Eliminar un mensaje
```
Opción: 9
ID del chat: alice:bob
ID del mensaje a eliminar: 42
🗑️ Eliminando mensaje 42 de alice:bob...
```
*Nota: Solo puedes eliminar mensajes del chat del que eres participante.*

### 9. Eliminar múltiples mensajes
```
Opción: 10
ID del chat: alice:bob
IDs de mensajes a eliminar (separados por coma): 40, 41, 42
🗑️ Eliminando 3 mensajes de alice:bob...
```

### 10. Ver estado
```
Opción: 11
Usuario: bob
📊 Obteniendo estado de bob...
```

## 🔔 Notificaciones

El cliente recibe notificaciones en tiempo real:
- **Nuevos mensajes**: Cuando alguien te escribe
- **Nuevos chats**: Cuando te agregan a un grupo
- **Mensajes offline**: Al reconectar, verás mensajes pendientes

Ejemplo:
```
💬 MENSAJE NUEVO:
   De: bob
  Chat: alice:bob
   Contenido: Hola Alice!
```

## 🐛 Troubleshooting

### Error: "No hay conexión WebSocket activa"
- Verifica que el servidor Elixir esté corriendo
- Asegúrate de haber iniciado sesión correctamente

### Error: "Error de conexión"
- Confirma que el servidor esté en `http://localhost:4000`
- Verifica que no haya firewall bloqueando el puerto 4000

### Mensajes no llegan
- Revisa que el ID del chat sea correcto (usa "Ver chats" primero)
- Verifica que seas participante del chat

## 🏗️ Arquitectura

```
┌─────────────┐           HTTP POST          ┌──────────────┐
│   client.py │ ────────────────────────────> │   Servidor   │
│  (Python)   │         /api/register         │    Elixir    │
│             │         /api/login            │   (Cowboy)   │
│             │                               │              │
│             │ <──────────────────────────>  │              │
│             │       WebSocket (:4000/ws)    │              │
│             │    JSON actions (bidirec.)    │              │
└─────────────┘                               └──────────────┘
```

### Protocolo WebSocket

Todas las acciones siguen el formato:
```json
{
  "action": "nombre_accion",
  "username": "usuario_actual",
  ...parametros adicionales
}
```

Acciones soportadas:
- `get_contacts` - Lista contactos
- `add_contact` - Agrega contacto
- `get_chatrooms` - Lista chats
- `create_group_chat` - Crea grupo
- `send_message` - Envía mensaje
- `get_messages` - Obtiene mensajes
- `search_messages` - Busca mensajes
- `get_status` - Estado de usuario

## 📊 Features Implementadas

✅ Registro y login con validación  
✅ Lista de contactos (ver + agregar)  
✅ **Bloqueo de contactos (bidireccional)**  
✅ Chats individuales automáticos  
✅ Chats grupales con múltiples participantes  
✅ Envío de mensajes  
✅ Ver últimos 10 mensajes  
✅ Búsqueda de mensajes por palabra clave  
✅ **Eliminación de mensajes (simple y lote)**  
✅ Estado de usuarios (online/offline/last_seen)  
✅ Notificaciones en tiempo real  
✅ Cola de notificaciones offline  

## 🔒 Seguridad

- Las contraseñas se hashean con Bcrypt en el servidor
- Las contraseñas nunca se muestran en el cliente
- Validaciones de longitud mínima (usuario ≥3, password ≥6)

## 💡 Notas

- El cliente usa threading para manejar mensajes entrantes sin bloquear la UI
- Los mensajes del servidor se imprimen automáticamente en pantalla
- El cliente se puede interrumpir con Ctrl+C de forma segura
- Las respuestas del servidor tienen un pequeño delay (0.3-0.5s) para visualización
