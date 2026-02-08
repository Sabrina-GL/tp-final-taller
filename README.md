# Sistema de Chat con Elixir + OTP

## Descripcion

Sistema de chat cliente-servidor desarrollado en Elixir usando OTP y WebSocket (Cowboy). Soporta chats individuales y grupales con comunicacion en tiempo real.

## Documentacion

- [chat_app/README.md](chat_app/README.md) - Guia tecnica del backend (API, modulos, configuracion, troubleshooting)
- [ARQUITECTURA.md](ARQUITECTURA.md) - Decisiones y diagrama general
- [DESARROLLO.md](DESARROLLO.md) - Lineamientos de desarrollo
- [CHECKLIST.md](CHECKLIST.md) - Checklist de entrega
- [PROXIMOS_PASOS.md](PROXIMOS_PASOS.md) - Mejoras pendientes
- [RESUMEN_CONFIGURACION.md](RESUMEN_CONFIGURACION.md) - Resumen de configuraciones
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
CHECKLIST.md       # Checklist de entrega
PROXIMOS_PASOS.md  # Roadmap
```

## Caracteristicas implementadas

### Core
- ✅ Alta de usuarios (registro con contrasena)
- ✅ Autenticacion
- ✅ Estado de conexion (activo/inactivo)
- ✅ Lista de contactos
- ✅ Chats individuales (1-a-1)
- ✅ Chats grupales

### Mensajes
- ✅ Ultimos 10 mensajes en cada conversacion
- ✅ Busqueda de mensajes por palabra clave
- ✅ Notificaciones de mensajes pendientes

### Opcionales
- ⏳ Envio de imagenes/archivos
- ⏳ Bloquear contactos
- ⏳ Borrar mensajes
- ⏳ Backups de mensajes

## Licencia

Trabajo practico para Taller de Programacion I - Catedra Manuel Camejo