# Sistema de Chat con Elixir + OTP

Sistema de chat cliente-servidor con backend en Elixir/OTP y comunicación en tiempo real por WebSocket (Cowboy).

## Resumen para tribunal

- Requisitos obligatorios de la consigna: ✅ completos.
- Features opcionales implementadas: ✅ 5/5.
- Cliente de consola funcional con todas las features: ✅.
- Arquitectura OTP con supervisores, registries y GenServers: ✅.

## Documentación

### Uso y demo
- [DEMO.md](DEMO.md) - Guion de demostración en vivo (consola + web)
- [CLIENT_README.md](CLIENT_README.md) - Uso del cliente por consola

### Técnica
- [ARQUITECTURA.md](ARQUITECTURA.md) - Arquitectura OTP y flujos
- [DESARROLLO.md](DESARROLLO.md) - Guía de desarrollo, debug y release
- [ESTADO.md](ESTADO.md) - Estado de cumplimiento vs consigna
- [COBERTURA_TESTS.md](COBERTURA_TESTS.md) - Cobertura de tests
- [consigna-tp-final.txt](consigna-tp-final.txt) - Enunciado original

## Inicio rápido (2 minutos)

### Opción recomendada (Docker)
```bash
cd tp-final-taller
make setup-docker
newgrp docker
make setup-dockerized
make docker-logs
python3 client.py
```

Alternativa sin reiniciar sesión:
```bash
make setup-docker
make setup-dockerized-sudo
```

### Opción local (sin Docker)
```bash
cd tp-final-taller
make setup
make dev
python3 client.py
```

Servidor:
- HTTP: `http://localhost:4000`
- WebSocket: `ws://localhost:4000/ws?user=username`

## Capacidades implementadas

- ✅ Autenticación y usuarios: registro/login con validaciones y hash Bcrypt.
- ✅ Conectividad: estado online/offline con `last_seen`.
- ✅ Contactos y chats: alta/listado, bloqueo bidireccional, chats 1-a-1 y grupales.
- ✅ Mensajería: últimos 10 mensajes, búsqueda por keyword, borrado simple y múltiple.
- ✅ Notificaciones: tiempo real + cola offline con entrega al reconectar.
- ✅ Archivos: `send_file` con Base64 (máx. 5MB), validación MIME y descarga por `/uploads/:filename`.
- ✅ Persistencia: PostgreSQL/Ecto para usuarios, contactos, chats y mensajes.
- ✅ Backups de mensajes: backup/restore manual con `pg_dump`/`pg_restore` (Docker y local).
- ✅ Clientes: consola Python y frontend web básico.

## API (resumen)

REST:
- `POST /api/register`
- `POST /api/login`
- `GET /api/status?user=username`

WebSocket (`/ws?user=username`):
- Contactos/chats: `get_contacts`, `add_contact`, `block_contact`, `get_chatrooms`, `create_group_chat`, `get_status`.
- Mensajes: `get_messages`, `send_message`, `send_file`, `delete_message`, `delete_messages`, `search_messages`.

## Testing y calidad

```bash
make test
cd chat_app && mix test --cover
```

Última corrida registrada (vigente a la fecha de actualización):
- `133 tests, 0 failures`
- Cobertura total: `81.77%` (umbral `80%`)

Fuente canónica de métricas y procedimiento: [COBERTURA_TESTS.md](COBERTURA_TESTS.md).

## Backups (MVP)

Docker:
```bash
make db-backup-docker
make db-restore-docker FILE=backups/postgres/<archivo.dump>
make db-backup-verify-docker
```

Local (sin Docker):
```bash
make db-backup-local
make db-restore-local FILE=backups/postgres/<archivo.dump>
```

Notas:
- Los dumps se guardan en `backups/postgres/` con timestamp.
- Se conserva automáticamente el histórico de los últimos 7 backups.
- El restore por defecto apunta a `chat_app_restore` (no pisa `chat_app_dev`).

## Estado del proyecto

- ✅ Requisitos obligatorios de la consigna: completos
- ✅ Opcionales implementados: frontend web, bloqueo, borrado, envío de archivos y backups
- ✅ Pendientes críticos: ninguno

## Documentación del proyecto

- [DEMO.md](DEMO.md) - Guion de demostración en vivo (consola + web).
- [CLIENT_README.md](CLIENT_README.md) - Uso del cliente por consola.
- [ARQUITECTURA.md](ARQUITECTURA.md) - Arquitectura OTP y flujos técnicos.
- [DESARROLLO.md](DESARROLLO.md) - Guía de desarrollo, debugging y release.
- [ESTADO.md](ESTADO.md) - Cumplimiento vs consigna con evidencia.
- [COBERTURA_TESTS.md](COBERTURA_TESTS.md) - Cobertura y última corrida registrada.
- [consigna-tp-final.txt](consigna-tp-final.txt) - Enunciado original.

## Licencia

Trabajo práctico para Taller de Programación I - Cátedra Manuel Camejo.