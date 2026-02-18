# Arquitectura del Sistema de Chat

## Resumen

Sistema de chat en tiempo real con **Elixir + OTP**, WebSocket (Cowboy) y persistencia en PostgreSQL.

**Stack**: Elixir/OTP, Cowboy, Ecto, PostgreSQL, WebSocket, ETS (cache en-memoria).

**Módulos principales**: 
- `ChatWeb.Router` → HTTP/WebSocket gateway
- `ChatWeb.SocketHandler` → Manejo de conexiones WebSocket
- `ChatApp.Accounts` → Usuarios y autenticación (con Ecto)
- `ChatApp.ChatManager` → Orquestación de chats
- `ChatApp.ChatRoomServer` → Lógica de salas (memoria + PostgreSQL)
- `ChatApp.ActivityServer` → Estado online/offline

**Persistencia**:
- Usuarios y credenciales en PostgreSQL (Ecto)
- Mensajes en PostgreSQL (historial completo)
- Estado online/offline en memoria (ETS + GenServer)
- Contactos en PostgreSQL (Ecto)
- Salas de chat en PostgreSQL (Ecto)

## Diagrama simplificado

```
Clientes (Web/CLI)
    ↓
Router (HTTP/WebSocket)
    ↓
SocketHandler
    ↓
ChatManager + ChatRoomServer + Accounts + ActivityServer
    ↓
PostgreSQL (Ecto) + ETS (memoria)


```

