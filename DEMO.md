# Demo del Proyecto - TP Final

## Objetivo de la demo

Mostrar en vivo que el sistema cumple los requisitos de la consigna: OTP, WebSocket, cliente funcional, features de mensajería y notificaciones offline.

## Duración sugerida

- Guion mínimo aprobatorio: 8-10 minutos.
- Extensión opcional (web + cobertura): 3-5 minutos.

## Preparación rápida (5 minutos antes)

```bash
cd tp-final-taller
make setup-docker
newgrp docker
make setup-dockerized
make docker-reset
pip install -r requirements.txt
```

Alternativa sin relogin:
```bash
make setup-docker
make setup-dockerized-sudo
make docker-reset-sudo
```

## Demo principal (cliente consola)

### Terminal 1 - Servidor
```bash
cd tp-final-taller
make docker-logs
```

### Terminal 2 - Alice
```bash
cd tp-final-taller
python3 client.py
```

### Terminal 3 - Bob
```bash
cd tp-final-taller
python3 client.py
```

## Guion mínimo aprobatorio (consola)

1. **Registro/Login (1 min)**
   - Alice: `alice / alice123`
   - Bob: `bob / bob123456`

2. **Contactos y chat 1-a-1 (1 min)**
   - Alice: Opción `2` (agregar contacto) → `bob`
   - Alice: Opción `4` (ver chats) → validar chat automático `alice:bob`

3. **Mensajes en tiempo real (1 min)**
   - Alice: Opción `6` en `alice:bob`
   - Bob recibe notificación inmediata

4. **Historial y búsqueda (1 min)**
   - Bob: Opción `7` (ver mensajes)
   - Bob: Opción `8` (buscar palabra clave)

5. **Chat grupal (1 min)**
   - Bob: Opción `5` (crear grupo) con Alice

6. **Estado de usuario (30 s)**
   - Alice: Opción `11` sobre Bob

7. **Bloqueo bidireccional y borrado (2 min)**
   - Bob: Opción `3` bloquea a Alice
   - Mostrar que el envío queda restringido
   - Alice: Opción `9` (simple)
   - Alice: Opción `10` (múltiple)

8. **Offline + archivos (2-3 min)**
   - Bob: Opción `13` (salir)
   - Alice envía mensaje con opción `6`
   - Bob reloguea y recibe pendientes
    - Alice: Opción `12`
    - Chat: `alice:bob`
    - Ruta: `/tmp/test.png`
    - Bob recibe notificación con archivo y URL de descarga

## Extensión opcional: demo web (resumen)

1. Abrir `http://localhost:4000` en dos ventanas (Alice y Bob)
2. Registrar/login ambos usuarios
3. Agregar contacto, enviar mensaje y validar recepción en vivo
4. Mostrar búsqueda y estados

## Evidencia de calidad (opcional)

```bash
cd tp-final-taller
make demo-smoke
make test
cd chat_app && mix test --cover
```

Métricas vigentes: ver [COBERTURA_TESTS.md](COBERTURA_TESTS.md).

Verificación rápida de backups:
```bash
cd tp-final-taller
make db-backup-verify-docker
```

## Troubleshooting mínimo

- **Sin conexión WebSocket**: verificar `make docker-logs`; el cliente reintenta reconexión automática.
- **Token inválido/expirado**: reloguear usuario para renovar sesión WebSocket.
- **Error Docker socket**: usar comandos `-sudo` o `newgrp docker`.
