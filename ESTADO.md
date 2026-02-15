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
- **59 tests** implementados con **74.68% de cobertura**
- Tests unitarios para: Accounts, ActivityTracker, ChatManager, ChatRoom, Notifications
- Tests de integración para: Router (HTTP endpoints)
- Todos los tests pasan exitosamente ✅

### Frontend básico (opcional implementado)
- HTML/CSS con conexión WebSocket
- Páginas: registro, login, chat
- Cliente web funcional en `priv/static/`

## 🔧 Mejoras recientes aplicadas
- **Corregido**: Manejo de errores en send_message (retorna error si usuario no es participante)
- **Corregido**: Notificaciones ahora excluyen al remitente
- **Corregido**: Consistencia en notificaciones de create_group_chat (no notifica al creador)
- **Eliminado**: Código muerto (función `open_chat_room/2`)
- **Eliminado**: Warnings de compilación (variable `pid` sin usar)

## ⏳ Pendiente (features opcionales de la consigna)

### Cliente por consola
- Cliente interactivo que use todas las features vía WebSocket
- Actualmente se puede interactuar por IEx o navegador web

### Opcionales no implementados
- ❌ Envío de archivos/imágenes
- ❌ Bloqueo de contactos
- ❌ Borrar mensajes
- ❌ Backups de mensajes

## 📋 Próximos pasos sugeridos (en orden de prioridad)

### 1. Cliente por consola (REQUERIDO por consigna)
- Python/Node.js que se conecte vía WebSocket
- Permite probar todas las features sin navegador
- **Prioritario**: Es un requisito explícito de la consigna

### 2. Mejorar cobertura de tests
- Agregar tests para SocketHandler (WebSocket)
- Alcanzar >80% de cobertura total
- Tests de integración end-to-end

### 3. Persistencia (mejora robustez)
- Implementar Ecto + SQLite para usuarios y mensajes
- Permite recuperar datos después de reiniciar servidor
- Evita pérdida de información

### 4. Features opcionales
- Envío de archivos (Base64 vía WebSocket)
- Bloqueo de contactos
- Borrar mensajes

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
| Cliente por consola | ❌ **FALTA** |
| Tests básicos | ✅ 59 tests, 74.68% cobertura |
| OTP correctamente | ✅ Supervision tree completo |

## 🎯 Estado general

**El proyecto cumple con todos los requisitos obligatorios de features**, pero **falta el cliente por consola** que es explícitamente mencionado en la consigna. El frontend web HTML/CSS implementado es un opcional, pero no reemplaza el requisito del cliente por consola.

**Código limpio**: ✅ Warnings eliminados, errores corregidos, código modular
**Documentación**: ✅ README claro, instrucciones completas
**Tests**: ✅ Cobertura aceptable (74.68%)
**OTP**: ✅ Uso correcto de supervisores y GenServers
