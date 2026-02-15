# Estado del Proyecto - TP Final

## Implementado (codigo actual)

### OTP y estructura
- Supervisor principal con estrategia one_for_one
- Registries para usuarios y salas
- GenServers: Accounts, ChatManager, ChatRoom, ActivityTracker (estructura)
- DynamicSupervisor para salas de chat

### Usuarios y contactos
- Registro y autenticacion basica (password en texto plano)
- Alta de contactos y listado

### Chats
- Creacion de chats 1-a-1
- Creacion de chats grupales
- Almacenamiento de ultimos 10 mensajes por sala
- Busqueda por palabra clave dentro de una sala

### API
- REST: POST /api/register, POST /api/login
- WebSocket: get_contacts, get_chatrooms, get_messages, add_contact, create_group_chat, send_message

### Notificaciones
- Notifica nuevos mensajes y nuevas salas solo a usuarios online

## Pendiente (segun consigna)

### Estado de conexion
- Registrar activo/inactivo
- Guardar desde cuando
- API para consultar estado

### Notificaciones offline
- Cola de mensajes pendientes por usuario
- Entrega al reconectar

### Seguridad y validaciones
- Hash de passwords (bcrypt)
- Validaciones de usuario y password

### Robustez
- Validar participantes antes de enviar mensaje
- Manejo de desconexion WebSocket
- Tests unitarios y de integracion

### Opcionales
- Envio de archivos/imagenes
- Bloqueo de contactos
- Borrar mensajes
- Backups de mensajes

## Continuar por aqui (orden sugerido)

1. ActivityTracker real: user_online, user_offline, is_online, last_seen
2. Notificaciones offline: cola en memoria + entrega al reconectar
3. Accounts: hashing y validaciones
4. ChatRoom: validar participante en add_message
5. Tests basicos para Accounts, ChatManager, ChatRoom

## Notas
- Ver detalles tecnicos en ARQUITECTURA.md y DESARROLLO.md
- README refleja solo lo implementado actualmente
