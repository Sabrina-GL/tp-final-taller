# Sistema de Chat con Elixir + OTP

## Descripcion

Sistema de chat cliente-servidor desarrollado en Elixir usando OTP y WebSocket (Cowboy). Soporta chats individuales y grupales con comunicacion en tiempo real.

## Documentacion

### Para Usuario / Demostración
- [DEMO.md](DEMO.md) - 🎬 Guía paso a paso para demostración en vivo
- [CLIENT_README.md](CLIENT_README.md) - 🐍 Guía completa del cliente por consola (Python)

### Para Desarrollador / Testing
- [chat_app/README.md](chat_app/README.md) - 📚 Guía técnica del backend (API, módulos, configuración, troubleshooting)
- [COBERTURA_TESTS.md](COBERTURA_TESTS.md) - 📊 Análisis detallado de cobertura de tests (85.12%)
- [ARQUITECTURA.md](ARQUITECTURA.md) - 🏗️ Decisiones de arquitectura y diagrama
- [DESARROLLO.md](DESARROLLO.md) - 🛠️ Lineamientos de desarrollo
- [ESTADO.md](ESTADO.md) - ✅ Resumen de features implementados vs pendientes
- [consigna-tp-final.txt](consigna-tp-final.txt) - 📋 Enunciado original del trabajo

## Inicio rapido

### 1. Setup inicial (Docker recomendado)
```bash
cd tp-final-taller
make setup-docker              # una vez (agrega usuario a grupo docker)
newgrp docker                  # activa grupo docker sin relogin
make setup-dockerized          # build + up + status
```

**Alternativa sin reiniciar sesión:**
```bash
make setup-docker
make setup-dockerized-sudo     # usa sudo para arrancar sin relogin
```

### 2. Servidor y clientes
```bash
make docker-logs  # ver logs del backend en contenedor
python3 client.py
```

El servidor estará disponible en `http://localhost:4000` y WebSocket en `ws://localhost:4000/ws`.

### 3. Alternativa local (sin Docker)
```bash
make setup
make dev
```

### 4. Cliente por Consola (Python)
```bash
cd tp-final-taller
python3 client.py
```

Sigue el menú interactivo para registrarte, iniciar sesión y usar el chat.

**Documentación**: Ver [CLIENT_README.md](CLIENT_README.md)

## Comandos Útiles

```bash
make help         # Muestra todos los comandos disponibles
make setup        # Setup completo del proyecto
make setup-dockerized # Setup completo usando Docker
make demo         # Prepara demo (BD limpia + guía rápida)
make test         # Ejecuta tests (133 tests, 85.12% cobertura)
make db-reset     # Limpia BD y la reinicia (usa antes de demo)
make reset-all    # Reinicio total (docker + SQLite + build + caches)
make setup-docker # Configura permisos para docker sin sudo (requiere relogin)
make docker-reset # Reinicia contenedores y volúmenes
make clean        # Limpia artifacts de compilación
```

## Docker (recomendado para producción)

El proyecto funciona con SQLite local y **no requiere Docker** para desarrollo rápido.
Docker es recomendado para entornos consistentes y despliegue:

```bash
make setup-docker           # agrega usuario a grupo docker
newgrp docker               # activa grupo sin relogin
make setup-dockerized       # build + up + status
make docker-logs            # ver logs del backend
make docker-down            # detener contenedores
```

**Alternativa sin reiniciar sesión:**
```bash
make setup-docker
make docker-up-sudo         # usa sudo directamente
make docker-logs-sudo       # ver logs con sudo
```

Si ves `permission denied /var/run/docker.sock`:
- Usa `newgrp docker` para activar el grupo sin relogin
- O usa comandos con `-sudo`: `make docker-up-sudo`
- O ejecuta `make setup-docker`, cierra sesión y vuelve a entrar (solución permanente)

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
- ✅ WebSocket: get_contacts, get_chatrooms, get_messages, get_status, add_contact, block_contact, create_group_chat, send_message, search_messages, delete_message, delete_messages

### Testing ✅
- ✅ 133 tests unitarios y de integración
- ✅ 85.12% de cobertura de código (incluye schemas Ecto)
- ✅ Tests para: Accounts, ChatManager, ChatRoom, ActivityServer, Notifications, Router, SocketHandler

### Cobertura de tests (resumen) ✅
- **Total**: 85.12% (133 tests)
- **SocketHandler**: 85.71% con tests unitarios directos de callbacks
- **Módulos core**: >= 85% en Accounts, ChatManager, ActivityServer, Notifications
- **Persistencia**: Ecto + SQLite (Schemas User y Message)
- Ejecutar: `mix test --cover`

### Opcionales
- ✅ Front-end HTML/CSS con WebSocket (básico funcional)
- ✅ Cliente por consola interactivo (Python con WebSocket)
- ✅ Bloquear contactos
- ✅ Borrar mensajes
- ⏳ Envío de imágenes/archivos
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