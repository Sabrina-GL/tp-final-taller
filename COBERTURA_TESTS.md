# Cobertura de Tests - TP Final

## Estado actual

Este archivo resume **cómo medir cobertura** y **cómo reportar resultados vigentes**.
Se toma como **fuente canónica** para métricas de tests/cobertura en el proyecto.

Última actualización del documento: 2026-02-26.

### Última corrida registrada

- Comando: `mix test --cover`
- Resultado tests: `173 tests, 0 failures`
- Cobertura total: `82.66%`
- Umbral configurado: `80.00%`
- Estado del comando: exitoso (exit code 0)
- Vigencia: estos valores corresponden a la última actualización de este documento.

### Resumen por módulo (última corrida)

- `ChatApp.Repo`: `50.00%`
- `ChatApp.Application`: `57.14%`
- `ChatApp.Schemas.User`: `60.00%`
- `ChatApp.ActivityServer`: `64.86%`
- `ChatWeb.SocketHandler`: `75.25%`
- `ChatApp.Notifications`: `76.00%`
- `ChatApp.AuthToken`: `77.78%`
- `ChatWeb.Router`: `82.00%`
- `ChatApp.ChatRoomServer`: `86.61%`
- `ChatApp.ChatManager`: `86.96%`
- `ChatApp.FileManager`: `91.43%`
- `ChatApp.Accounts`: `93.62%`
- `ChatApp.ActivitySupervisor`: `100.00%`
- `ChatApp.ChatRoomSupervisor`: `100.00%`
- `ChatApp.Schemas.Chatroom`: `100.00%`
- `ChatApp.Schemas.Contact`: `100.00%`
- `ChatApp.Schemas.Message`: `100.00%`

## Cómo ejecutar

```bash
cd chat_app
mix test --cover
```

## Qué registrar después de correr

- Porcentaje total de cobertura informado por `mix test --cover`.
- Cantidad total de tests y número de fallos.
- Módulos con menor cobertura para priorizar mejoras.

## Notas

- Los valores de cobertura y conteo de tests **pueden variar** entre corridas según cambios recientes.
- Para resultados reproducibles, ejecutar sobre una base de datos de test limpia.
- Los logs de `Postgrex.Protocol ... disconnected: tcp recv (idle): closed` pueden aparecer durante la recreación/cierre de conexiones de la DB de test; si el comando termina con `0 failures` y `exit code 0`, no se considera fallo funcional.
