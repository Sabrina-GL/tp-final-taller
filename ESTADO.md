# Estado del Proyecto - TP Final

## ✅ Implementado (código actual)

### OTP y estructura
- Supervisor principal con estrategia one_for_one
- Registries: UsersRegistry (conexiones WebSocket), ActivityRegistry (estado usuarios), ChatRoomsRegistry (salas activas)
- NUEVO: ActivitySupervisor (DynamicSupervisor) para procesos de usuario
- NUEVO: ActivityServer (GenServer) por usuario para estado online/offline y notificaciones pendientes
- ChatRoomSupervisor (DynamicSupervisor) para salas de chat
- ChatRoomServer (GenServer) por sala para mensajes
- ChatManager -> NO es GenServer (módulo normal de orquestación)
- Accounts -> NO es GenServer (módulo normal con Ecto)

### Usuarios y contactos
- Registro y autenticación con hash de password (Bcrypt)
- Validaciones: username ≥3 chars, password ≥6 chars
- Alta de contactos y listado
- Creación automática de chat privado al agregar contacto

### Chats
- Creación de chats 1-a-1 (privados)
- Creación de chats grupales (múltiples participantes)
- Almacenamiento de últimos 10 mensajes por sala (con persistencia en PostgreSQL)
- Búsqueda por palabra clave dentro de una sala
- Validación de participante al enviar mensaje (rechaza no-participantes)
- Notificaciones a participantes (excepto remitente)
- Persistencia completa de mensajes en PostgreSQL (tabla messages)

### 🔄 Persistencia con Ecto + PostgreSQL (NUEVO)
- ✅ Usuarios almacenados en PostgreSQL (no se pierden en reinicios)
- ✅ Contactos almacenados en PostgreSQL (tabla contacts con relación user-contact)
- ✅ Salas de chat almacenadas en PostgreSQL (tabla chatrooms con campo participants array)
- ✅ Mensajes almacenados en PostgreSQL (historial completo)
- ✅ Contraseñas hasheadas con Bcrypt en base de datos
- ✅ Migrations automáticas aplicadas en test/dev/prod
- ✅ Contactos y estado online en ETS (caché rápido)
- ✅ Base de datos: `chat_app_dev` (PostgreSQL)

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
- Cola de notificaciones offline (almacenadas en ActivityServer)
- Si no existe proceso de actividad para el usuario, se crea vía ActivitySupervisor antes de encolar
- Entrega automática de notificaciones pendientes al reconectar
- Registro de estado online/offline por usuario
- Timestamp de última conexión (last_seen)

### 🖥️ Clientes Disponibles (DOS opciones)

#### Cliente Web (HTML/CSS)
- Interfaz gráfica en navegador
- Acceso: `http://localhost:4000`
- Páginas: registro, login, chat
- Features: Contactos, chats 1-a-1, chats grupales, mensajes, búsqueda, notificaciones en tiempo real
- Archivos: `priv/static/index.html`, `login.html`, `register.html`, `application.js`, CSS

#### Cliente por Consola (Python)
- Cliente interactivo en Python
- Archivo: `client.py` (en raíz del proyecto)
- WebSocket con todas las features
- Menú interactivo con 12 opciones principales
- Notificaciones en tiempo real
- Documentación: [CLIENT_README.md](CLIENT_README.md)

### Testing
- Suite de tests automatizada implementada
- Cobertura verificable con `mix test --cover`
- Tests unitarios para: Accounts, ActivityServer, ChatManager, ChatRoomServer, Notifications, SocketHandler
- Tests de integración para: Router (HTTP endpoints)
- `mix test`: pasa exitosamente ✅
- `mix test --cover`: reporta cobertura con threshold configurado en 80% y su estado depende de la corrida actual
- Nota: los valores exactos de cobertura y conteo pueden variar según la última corrida

## 🔧 Mejoras recientes aplicadas
- **Reestructuración OTP**: Separación de responsabilidades (ActivityServer por usuario, ChatRoomServer por sala)
- **Eliminado**: Accounts como GenServer (ahora contexto Ecto)
- **Eliminado**: ChatManager como GenServer (ahora módulo normal)
- **Eliminado**: ActivityTracker (reemplazado por ActivitySupervisor + ActivityServer)
- **Agregado**: ActivitySupervisor (DynamicSupervisor) para procesos de usuario
- **Agregado**: Recreación automática de procesos desde DB
- **Agregado**: Schema Chatroom con campo participants array
- **Corregido**: Manejo de errores en send_message (retorna error si usuario no es participante)
- **Corregido**: Notificaciones ahora excluyen al remitente
- **Corregido**: Consistencia en notificaciones de create_group_chat (no notifica al creador)
- **Corregido**: Notificaciones offline garantizan proceso ActivityServer antes de encolar pendientes
- **Eliminado**: Código muerto (función `open_chat_room/2`)
- **Eliminado**: Warnings de compilación (variable `pid` sin usar)

## ⏳ Pendiente (features opcionales de la consigna)

### Opcionales no implementados
- ❌ Envío de archivos/imágenes
- ❌ Backups de mensajes

**NOTA**: Todos los requisitos obligatorios de la consigna están completos, incluyendo el cliente por consola.

## 📋 Próximos pasos sugeridos (en orden de prioridad)

### 1. Mantener cobertura alta
- Mantener >= 90% de cobertura total
- Tests de integración end-to-end (opcional)

### 2. Robustez y observabilidad
- Mejorar métricas y logging estructurado para flujos WebSocket
- Añadir alertas de salud (estado de supervisores/procesos clave)
- Incorporar tests de estrés para reconexiones y cola offline

### 3. Features opcionales
- Envío de archivos (Base64 vía WebSocket)
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
| Tests básicos | ✅ Suite automatizada + cobertura ejecutable |
| OTP correctamente | ✅ Supervision tree completo |

## 🎯 Estado general

**El proyecto cumple con todos los requisitos obligatorios de features**, incluyendo el **cliente por consola** que se solicita en la consigna.

**Código limpio**: ✅ Warnings eliminados, errores corregidos, código modular
**Documentación**: ✅ README claro, instrucciones completas
**Tests**: ✅ Cobertura sólida (medible en cada ejecución)
**OTP**: ✅ Uso correcto de supervisores y GenServers
