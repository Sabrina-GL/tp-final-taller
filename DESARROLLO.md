# Guía de Desarrollo

## Setup local (sin Docker)

```bash
cd tp-final-taller/chat_app
mix deps.get
mix ecto.create
mix ecto.migrate
iex -S mix
```

## Setup con Docker

```bash
cd tp-final-taller
make setup-docker
newgrp docker
make setup-dockerized
make docker-logs
```

## Estructura OTP (resumen)

- `ChatApp.Application`: árbol de supervisión
- `ActivitySupervisor` / `ActivityServer`: actividad y cola offline por usuario
- `ChatRoomSupervisor` / `ChatRoomServer`: salas y mensajes por chat
- Registries: `UsersRegistry`, `ActivityRegistry`, `ChatRoomsRegistry`

## Desarrollo diario

```bash
cd chat_app
mix compile
mix test
mix test --trace
mix format
```

## Testing y cobertura

```bash
cd chat_app
mix test --cover
```

Resultados y criterio de cobertura en [COBERTURA_TESTS.md](COBERTURA_TESTS.md).

## Debugging útil

```elixir
# Ver procesos registrados
Registry.lookup(ChatApp.UsersRegistry, "alice")

# Ver estado de una sala
case Registry.lookup(ChatApp.ChatRoomsRegistry, "alice:bob") do
	[{pid, _}] -> :sys.get_state(pid)
	[] -> :chat_no_encontrado
end
```

Para inspección de flujos HTTP/WS, usar logs del servidor (`make docker-logs` o `iex -S mix --logger-level debug`).

## Archivos y adjuntos

- Acción WS: `send_file`
- Gestión: `ChatApp.FileManager`
- Límite: 5MB
- Descarga: `GET /uploads/:filename`

## Release / producción

```bash
cd chat_app
MIX_ENV=prod mix compile
MIX_ENV=prod mix release
_build/prod/rel/chat_app/bin/chat_app start
```

## Backup y restore (PostgreSQL)

### Docker

```bash
cd tp-final-taller
make db-backup-docker
make db-restore-docker FILE=backups/postgres/<archivo.dump>
make db-backup-verify-docker
```

### Local

```bash
cd tp-final-taller
make db-backup-local
make db-restore-local FILE=backups/postgres/<archivo.dump>
```

Notas:
- Los backups se guardan en `backups/postgres/`.
- El restore usa por defecto `chat_app_restore` para evitar sobreescribir la base activa.
- Retención automática: últimos 7 dumps.

## Buenas prácticas

- Mantener módulos chicos y responsabilidades claras
- Escribir tests para cambios en lógica de negocio
- Evitar duplicar documentación: enlazar al documento canónico
- Verificar coherencia con [ESTADO.md](ESTADO.md) y [README.md](README.md)
