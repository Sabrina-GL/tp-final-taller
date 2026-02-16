# Arquitectura del Sistema de Chat

## Resumen

Sistema de chat en tiempo real con **Elixir + OTP**, WebSocket (Cowboy) y persistencia en SQLite.

**Stack**: Elixir/OTP, Cowboy, Ecto, SQLite, WebSocket, ETS (cache en-memoria).

**Módulos principales**: 
- `ChatWeb.Router` → HTTP/WebSocket gateway
- `ChatWeb.SocketHandler` → Manejo de conexiones WebSocket
- `ChatApp.Accounts` → Usuarios y autenticación (con Ecto)
- `ChatApp.ChatManager` → Orquestación de chats
- `ChatApp.ChatRoom` → Lógica de salas (memoria + SQLite)
- `ChatApp.ActivityTracker` → Estado online/offline

**Persistencia**:
- Usuarios y credenciales en SQLite (Ecto)
- Mensajes en SQLite (historial completo)
- Estado online/offline en memoria (ETS + GenServer)

## Diagrama simplificado

```
Clientes (Web/CLI)
    ↓
Router (HTTP/WebSocket)
    ↓
SocketHandler
    ↓
ChatManager + ChatRoom + Accounts
    ↓
SQLite (Ecto) + ETS (memoria)

