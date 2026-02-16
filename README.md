# Sistema de Chat con Elixir + OTP

## Descripcion

Sistema de chat cliente-servidor desarrollado en Elixir usando OTP y WebSocket (Cowboy). Soporta chats individuales y grupales con comunicacion en tiempo real.

## Documentacion

### Para Usuario / Demostración
- [DEMO.md](DEMO.md) - 🎬 Guía paso a paso para demostración en vivo
- [CLIENT_README.md](CLIENT_README.md) - 🐍 Guía completa del cliente por consola (Python)

### Para Desarrollador / Testing
- [chat_app/README.md](chat_app/README.md) - 📚 Guía técnica del backend (API, módulos, configuración, troubleshooting)
- [COBERTURA_TESTS.md](COBERTURA_TESTS.md) - 📊 Análisis detallado de cobertura de tests (87.37%)
- [ARQUITECTURA.md](ARQUITECTURA.md) - 🏗️ Decisiones de arquitectura y diagrama
- [DESARROLLO.md](DESARROLLO.md) - 🛠️ Lineamientos de desarrollo
- [ESTADO.md](ESTADO.md) - ✅ Resumen de features implementados vs pendientes
- [consigna-tp-final.txt](consigna-tp-final.txt) - 📋 Enunciado original del trabajo

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

### 2. Cliente por Consola (Python)
```bash
cd tp-final-taller
pip install -r requirements.txt
python3 client.py
```

Sigue el menú interactivo para registrarte, iniciar sesión y usar el chat.

**Documentación**: Ver [CLIENT_README.md](CLIENT_README.md)

### 3. Cliente Web (Navegador)
El servidor sirve una interfaz web en:
```
http://localhost:4000
```

Abre en tu navegador y:
1. Register (crear cuenta)
2. Login (inicia sesión)
3. Usa el chat desde la interfaz gráfica

**Características**: Contactos, chats 1-a-1, chats grupales, mensajes, búsqueda, notificaciones

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
- ✅ Usuarios y credenciales persistidos en SQLite (Ecto ORM)
- ✅ Estado de conexión (online/offline y last_seen)
- ✅ Lista de contactos (agregar y listar)
- ✅ Chats individuales (creación automática al agregar contacto)
- ✅ Chats grupales (múltiples participantes)

### Mensajes ✅
- ✅ Últimos 10 mensajes en cada conversación (persistidos en SQLite)
- ✅ Búsqueda de mensajes por palabra clave
- ✅ Validación de participantes (rechaza mensajes de no-participantes)
- ✅ Notificaciones en tiempo real (excepto al remitente)
- ✅ Cola de notificaciones offline con entrega automática al reconectar
- ✅ Historial completo de mensajes en base de datos (no se pierden en reinicios)

### API y WebSocket ✅
- ✅ REST: POST /api/register, POST /api/login
- ✅ REST: GET /api/status?user=usuario (estado de conexión)
- ✅ WebSocket: get_contacts, get_chatrooms, get_messages, get_status, add_contact, create_group_chat, send_message

### Testing ✅
- ✅ 103 tests unitarios y de integración
- ✅ 87.37% de cobertura de código (incluye schemas Ecto)
- ✅ Tests para: Accounts, ChatManager, ChatRoom, ActivityTracker, Notifications, Router, SocketHandler

### Cobertura de tests (resumen) ✅
- **Total**: 87.37% (103 tests)
- **SocketHandler**: 85.71% con tests unitarios directos de callbacks
- **Módulos core**: >= 85% en Accounts, ChatManager, ActivityTracker, Notifications
- **Persistencia**: Ecto + SQLite (Schemas User y Message)
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