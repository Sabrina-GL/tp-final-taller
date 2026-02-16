# Estado del Proyecto - TP Final

## ✅ Implementado (código actual)

### OTP y estructura
- Supervisor principal con estrategia one_for_one
- Registries para usuarios (UsersRegistry) y salas (ChatRoomsRegistry)
- GenServers: Accounts, ChatManager, ChatRoom, ActivityTracker
- DynamicSupervisor para salas de chat

### Usuarios y contactos
- Registro y autenticación con hash de password (Bcrypt)
- Validaciones: username ≥3 chars, password ≥6 chars
- Alta de contactos y listado
- Creación automática de chat privado al agregar contacto

### Chats
- Creación de chats 1-a-1 (privados)
- Creación de chats grupales (múltiples participantes)
- Almacenamiento de últimos 10 mensajes por sala
- Búsqueda por palabra clave dentro de una sala
- Validación de participante al enviar mensaje (rechaza no-participantes)
- Notificaciones a participantes (excepto remitente)

### API REST
- POST /api/register - Registro de usuario
- POST /api/login - Autenticación
- GET /api/status?user=username - Estado de conexión (online/offline, last_seen)
- GET /register, /login, /index - Páginas HTML

### WebSocket
Acciones disponibles:
- `get_contacts` - Obtener lista de contactos
- `get_chatrooms` - Obtener lista de chats del usuario
- `get_messages` - Obtener mensajes de un chat
- `get_status` - Consultar estado de un usuario
- `add_contact` - Agregar contacto (crea chat automáticamente)
- `create_group_chat` - Crear chat grupal
- `send_message` - Enviar mensaje (con manejo de errores)

### Notificaciones y estado
- Sistema de notificaciones en tiempo real vía WebSocket
- Cola de notificaciones offline (almacenadas en ActivityTracker)
- Entrega automática de notificaciones pendientes al reconectar
- Registro de estado online/offline por usuario
- Timestamp de última conexión (last_seen)

### Testing
- **104 tests** implementados con **93.09% de cobertura**
- Tests unitarios para: Accounts, ActivityTracker, ChatManager, ChatRoom, Notifications, SocketHandler
- Tests de integración para: Router (HTTP endpoints)
- Todos los tests pasan exitosamente ✅

### Frontend básico (opcional implementado)
- HTML/CSS con conexión WebSocket
- Páginas: registro, login, chat
- Cliente web funcional en `priv/static/`

### Cliente por consola (opcional implementado) ✅
- **Cliente Python interactivo** (`client.py`)
- WebSocket con todas las features: registro, login, contactos, chats, mensajes
- Menú interactivo con 9 opciones principales
- Notificaciones en tiempo real
- Documentación completa en [CLIENT_README.md](CLIENT_README.md)

## 🔧 Mejoras recientes aplicadas
- **Corregido**: Manejo de errores en send_message (retorna error si usuario no es participante)
- **Corregido**: Notificaciones ahora excluyen al remitente
- **Corregido**: Consistencia en notificaciones de create_group_chat (no notifica al creador)
- **Eliminado**: Código muerto (función `open_chat_room/2`)
- **Eliminado**: Warnings de compilación (variable `pid` sin usar)

## ⏳ Pendiente (features opcionales de la consigna)

### Opcionales no implementados
- ❌ Envío de archivos/imágenes
- ❌ Bloqueo de contactos
- ❌ Borrar mensajes
- ❌ Backups de mensajes

**NOTA**: Todos los requisitos obligatorios de la consigna están completos, incluyendo el cliente por consola.

## 📋 Próximos pasos sugeridos (en orden de prioridad)

### 1. Mantener cobertura alta
- Mantener >= 90% de cobertura total
- Tests de integración end-to-end (opcional)

### 2. Persistencia (mejora robustez)
- Implementar Ecto + SQLite para usuarios y mensajes
- Permite recuperar datos después de reiniciar servidor
- Evita pérdida de información

### 3. Features opcionales
- Envío de archivos (Base64 vía WebSocket)
- Bloqueo de contactos
- Borrar mensajes
- Backups automáticos

## 📊 Estado vs Consigna

| Feature Consigna | Estado |
|------------------|--------|
| Alta de usuarios | ✅ Implementado con validaciones |
| Estado de conexión | ✅ Online/offline + last_seen |
| Lista de contactos | ✅ Agregar y listar |
| Chats 1-a-1 | ✅ Funcionando |
| Chats grupales | ✅ Funcionando |
| Últimos 10 mensajes | ✅ Por sala |
| Búsqueda en mensajes | ✅ Por keyword |
| Notificaciones offline | ✅ Con cola y entrega |
| Documentación | ✅ README + ARQUITECTURA + DESARROLLO |
| Cliente por consola | ✅ **Python con WebSocket** |
| Tests básicos | ✅ 104 tests, 93.09% cobertura |
| OTP correctamente | ✅ Supervision tree completo |

## 🎯 Estado general

**El proyecto cumple con todos los requisitos obligatorios de features**, incluyendo el **cliente por consola** que se solicita en la consigna.

**Código limpio**: ✅ Warnings eliminados, errores corregidos, código modular
**Documentación**: ✅ README claro, instrucciones completas
**Tests**: ✅ Cobertura alta (93.09%)
**OTP**: ✅ Uso correcto de supervisores y GenServers
