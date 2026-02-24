# Estado del Proyecto - TP Final

## Resumen ejecutivo

- Requisitos obligatorios de la consigna: **completos**
- Features opcionales implementadas: **5/5**
- Pendiente: **ninguno**

## Cumplimiento vs consigna

| Feature | Tipo | Estado | Evidencia |
|---|---|---|---|
| Alta de usuarios | Obligatoria | ✅ Registro + login con validaciones | `README.md`, `DEMO.md` |
| Estado de conexión | Obligatoria | ✅ Online/offline + last_seen | `README.md`, `CLIENT_README.md` |
| Lista de contactos | Obligatoria | ✅ Agregar y listar | `CLIENT_README.md`, `DEMO.md` |
| Chats 1-a-1 | Obligatoria | ✅ Creación automática al agregar contacto | `DEMO.md` |
| Chats grupales | Obligatoria | ✅ Funcionales | `DEMO.md` |
| Últimos 10 mensajes | Obligatoria | ✅ Por conversación | `README.md` |
| Búsqueda de mensajes | Obligatoria | ✅ Por keyword | `CLIENT_README.md` |
| Notificaciones offline | Obligatoria | ✅ Cola + entrega al reconectar | `DEMO.md`, `ARQUITECTURA.md` |
| Cliente por consola | Obligatoria | ✅ Python/WebSocket | `CLIENT_README.md` |
| OTP correctamente aplicado | Obligatoria | ✅ Supervisores, Registries, GenServers | `ARQUITECTURA.md` |
| Documentación mínima | Obligatoria | ✅ README + docs de soporte | `README.md` |
| Envío de archivos/imágenes | Opcional | ✅ Implementado (`send_file`) | `CLIENT_README.md`, `ARQUITECTURA.md` |
| Frontend HTML/CSS | Opcional | ✅ Implementado | `README.md`, `DEMO.md` |
| Bloqueo de contactos | Opcional | ✅ Implementado | `CLIENT_README.md`, `DEMO.md` |
| Borrado de mensajes | Opcional | ✅ Implementado | `CLIENT_README.md`, `DEMO.md` |
| Backups de mensajes | Opcional | ✅ Implementado (`pg_dump`/`pg_restore`) | `README.md`, `DESARROLLO.md` |

## Features implementadas (resumen)

### Backend y OTP
- Supervisor principal `one_for_one`
- `ActivitySupervisor` + `ActivityServer` por usuario
- `ChatRoomSupervisor` + `ChatRoomServer` por sala
- `Accounts` y `ChatManager` como módulos de contexto

### Persistencia
- PostgreSQL con Ecto para usuarios, contactos, chats y mensajes
- Historial completo de mensajes y recuperación tras reinicio
- Backups y restore manuales con `pg_dump`/`pg_restore` (Docker y local)

### Mensajería
- Mensajes en tiempo real
- Búsqueda por palabra
- Eliminación simple y múltiple
- Bloqueo bidireccional de contactos

### Archivos
- Envío de archivos/imágenes por WebSocket (`send_file`)
- Base64 + límite 5MB + validación MIME
- Descarga por `GET /uploads/:filename`
- Limpieza automática al eliminar mensajes

### Clientes
- Cliente consola: `client.py`
- Cliente web básico: `priv/static/*`

## Testing y calidad

- Última corrida registrada: `166 tests, 0 failures`
- Cobertura registrada: `80.22%` (umbral `80%`)
- Fuente canónica y procedimiento: [COBERTURA_TESTS.md](COBERTURA_TESTS.md)

## Pendiente

- ✅ Sin pendientes funcionales relevantes para la consigna
