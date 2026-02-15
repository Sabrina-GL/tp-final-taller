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

1. **Iniciar el servidor Elixir** (en otra terminal):
```bash
cd chat_app
mix deps.get
iex -S mix
```

2. **Ejecutar el cliente**:
```bash
python3 client.py
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
3. Ver chats                  → Lista todos tus chats (1-1 y grupales)
4. Crear chat grupal          → Crea un nuevo grupo
5. Enviar mensaje             → Envía mensaje a un chat
6. Ver mensajes de un chat    → Obtiene últimos 10 mensajes
7. Buscar mensajes            → Busca por palabra clave en un chat
8. Ver estado de un usuario   → Muestra online/offline/last_seen
9. Salir                      → Cierra sesión
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
Usuario: alice
Contraseña: alice123
✅ Login exitoso. Bienvenido alice!
```

### 3. Agregar contacto
```
Opción: 2
Usuario a agregar: bob
👤 Agregando contacto: bob
```

### 4. Crear chat grupal
```
Opción: 4
Nombre del grupo: equipo
Participantes (separados por coma): bob, charlie
👥 Creando chat grupal: equipo
```

### 5. Enviar mensaje
```
Opción: 5
ID del chat: chat_alice_bob
Mensaje: Hola Bob, cómo estás?
📤 Enviando mensaje a chat_alice_bob...
```

### 6. Ver mensajes
```
Opción: 6
ID del chat: chat_alice_bob
📬 Obteniendo mensajes de chat_alice_bob...
```

### 7. Buscar mensajes
```
Opción: 7
ID del chat: chat_alice_bob
Palabra clave a buscar: reunión
🔍 Buscando 'reunión' en chat_alice_bob...
```

### 8. Ver estado
```
Opción: 8
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
   Chat: chat_alice_bob
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
- `identify` - Identifica al usuario conectado
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
✅ Chats individuales automáticos  
✅ Chats grupales con múltiples participantes  
✅ Envío de mensajes  
✅ Ver últimos 10 mensajes  
✅ Búsqueda de mensajes por palabra clave  
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
