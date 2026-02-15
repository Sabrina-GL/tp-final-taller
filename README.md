# Sistema de Chat con Elixir + OTP

## Descripcion

Sistema de chat cliente-servidor desarrollado en Elixir usando OTP y WebSocket (Cowboy). Soporta chats individuales y grupales con comunicacion en tiempo real.

## Documentacion

- [chat_app/README.md](chat_app/README.md) - Guia tecnica del backend (API, modulos, configuracion, troubleshooting)
- [ARQUITECTURA.md](ARQUITECTURA.md) - Decisiones y diagrama general
- [DESARROLLO.md](DESARROLLO.md) - Lineamientos de desarrollo
- [ESTADO.md](ESTADO.md) - Resumen de lo implementado y lo pendiente
- [consigna-tp-final.txt](consigna-tp-final.txt) - Enunciado del trabajo

## Inicio rapido

```bash
git clone <repository-url>
cd tp-final-taller/chat_app
mix deps.get
mix compile
iex -S mix
```

Servidor disponible en `http://localhost:4000`.

## Estructura principal

```
chat_app/          # Backend Elixir + OTP
ARQUITECTURA.md    # Arquitectura general
DESARROLLO.md      # Guia de desarrollo
ESTADO.md          # Estado del proyecto
```

## Caracteristicas implementadas

### Core
- ✅ Alta de usuarios (validaciones basicas + hash de password)
- ✅ Autenticacion con hash de password
- ✅ Estado de conexion (online/offline y last_seen)
- ✅ Lista de contactos (agregar y listar)
- ✅ Chats individuales (creacion de sala)
- ✅ Chats grupales (creacion de sala)

### Mensajes
- ✅ Ultimos 10 mensajes en cada conversacion
- ✅ Busqueda de mensajes por palabra clave
- ✅ Notificaciones con cola offline y entrega al reconectar

### API y WebSocket
- ✅ REST: /api/register y /api/login
- ✅ WebSocket: acciones get_contacts, get_chatrooms, get_messages, add_contact, create_group_chat, send_message

### Opcionales
- ⏳ Envio de imagenes/archivos
- ⏳ Bloquear contactos
- ⏳ Borrar mensajes
- ⏳ Backups de mensajes

## Licencia

Trabajo practico para Taller de Programacion I - Catedra Manuel Camejo