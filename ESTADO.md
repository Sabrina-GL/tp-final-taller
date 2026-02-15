# Estado del Proyecto - TP Final

## Implementado (codigo actual)

### OTP y estructura
- Supervisor principal con estrategia one_for_one
- Registries para usuarios y salas
- GenServers: Accounts, ChatManager, ChatRoom, ActivityTracker
- DynamicSupervisor para salas de chat

### Usuarios y contactos
- Registro y autenticacion con hash de password
- Alta de contactos y listado

### Chats
- Creacion de chats 1-a-1
- Creacion de chats grupales
- Almacenamiento de ultimos 10 mensajes por sala
- Busqueda por palabra clave dentro de una sala
- Validacion de participante al enviar mensaje

### API
- REST: POST /api/register, POST /api/login
- WebSocket: get_contacts, get_chatrooms, get_messages, add_contact, create_group_chat, send_message

### Notificaciones
- Notifica nuevos mensajes y nuevas salas con cola offline

### Estado de conexion
- Registrar activo/inactivo
- Guardar desde cuando

## Pendiente (segun consigna)

### Estado de conexion
- API para consultar estado

### Robustez
- Tests unitarios y de integracion

### Opcionales
- Envio de archivos/imagenes
- Bloqueo de contactos
- Borrar mensajes
- Backups de mensajes

## Continuar por aqui (orden sugerido)

1. API para consultar estado de conexion
2. Tests basicos para Accounts, ChatManager, ChatRoom, ActivityTracker
3. Cliente por consola (basico) para probar features
4. Mejoras de robustez (timeouts, limpieza de salas)

## Notas
- Ver detalles tecnicos en ARQUITECTURA.md y DESARROLLO.md
- README refleja solo lo implementado actualmente
