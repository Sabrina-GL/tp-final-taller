# Sistema de Chat con Elixir + OTP

## Descripcion

Sistema de chat cliente-servidor desarrollado en Elixir usando OTP y WebSocket (Cowboy). Soporta chats individuales y grupales con comunicacion en tiempo real.

## Documentacion

- [chat_app/README.md](chat_app/README.md) - Guia tecnica del backend (API, modulos, configuracion, troubleshooting)
- [CLIENT_README.md](CLIENT_README.md) - Guia completa del cliente por consola (Python)
- [DEMO.md](DEMO.md) - Guia paso a paso para la demostración en vivo
- [COBERTURA_TESTS.md](COBERTURA_TESTS.md) - Análisis detallado de cobertura de tests (93.09%)
- [ARQUITECTURA.md](ARQUITECTURA.md) - Decisiones y diagrama general
- [DESARROLLO.md](DESARROLLO.md) - Lineamientos de desarrollo
- [ESTADO.md](ESTADO.md) - Resumen de lo implementado y lo pendiente
- [consigna-tp-final.txt](consigna-tp-final.txt) - Enunciado del trabajo

## Inicio rapido

### 1. Servidor Elixir
```bash
git clone <repository-url>
cd tp-final-taller/chat_app
mix deps.get
mix compile
iex -S mix
```

Servidor disponible en `http://localhost:4000`.

### 2. Cliente por Consola
```bash
cd tp-final-taller
pip install -r requirements.txt
python3 client.py
```

Sigue el menú interactivo para registrarte, iniciar sesión y usar el chat.

## Estructura principal

```
chat_app/          # Backend Elixir + OTP
ARQUITECTURA.md    # Arquitectura general
DESARROLLO.md      # Guia de desarrollo
ESTADO.md          # Estado del proyecto
```

## Caracteristicas implementadas

### Core ✅
- ✅ Alta de usuarios con validaciones (username ≥3 chars, password ≥6 chars)
- ✅ Autenticación con hash de password (Bcrypt)
- ✅ Estado de conexión (online/offline y last_seen)
- ✅ Lista de contactos (agregar y listar)
- ✅ Chats individuales (creación automática al agregar contacto)
- ✅ Chats grupales (múltiples participantes)

### Mensajes ✅
- ✅ Últimos 10 mensajes en cada conversación
- ✅ Búsqueda de mensajes por palabra clave
- ✅ Validación de participantes (rechaza mensajes de no-participantes)
- ✅ Notificaciones en tiempo real (excepto al remitente)
- ✅ Cola de notificaciones offline con entrega automática al reconectar

### API y WebSocket ✅
- ✅ REST: POST /api/register, POST /api/login
- ✅ REST: GET /api/status?user=usuario (estado de conexión)
- ✅ WebSocket: get_contacts, get_chatrooms, get_messages, get_status, add_contact, create_group_chat, send_message

### Testing ✅
- ✅ 104 tests unitarios y de integración
- ✅ 93.09% de cobertura de código
- ✅ Tests para: Accounts, ChatManager, ChatRoom, ActivityTracker, Notifications, Router, SocketHandler

### Cobertura de tests (resumen) ✅
- **Total**: 93.09% (104 tests)
- **SocketHandler**: 85.71% con tests unitarios directos de callbacks
- **Módulos core**: >= 96% en Accounts, ChatManager, ActivityTracker, Notifications
- Ejecutar: `mix test --cover`

### Opcionales
- ✅ Front-end HTML/CSS con WebSocket (básico funcional)
- ✅ Cliente por consola interactivo (Python con WebSocket)
- ⏳ Envío de imágenes/archivos
- ⏳ Bloquear contactos
- ⏳ Borrar mensajes
- ⏳ Backups de mensajes

## Estado del proyecto

**Todos los requisitos obligatorios están implementados y funcionando.** El proyecto incluye:
- ✅ Estructura OTP completa (Supervisores, GenServers, Registries)
- ✅ WebSocket con Cowboy funcionando
- ✅ Todas las features obligatorias de la consigna
- ✅ Tests básicos con buena cobertura
- ✅ Documentación completa

**El proyecto cumple TODOS los requisitos de la consigna**, incluyendo el cliente por consola en Python que permite interactuar con todas las features vía WebSocket.

## Licencia

Trabajo practico para Taller de Programacion I - Catedra Manuel Camejo