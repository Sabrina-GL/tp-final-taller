# Cliente por Consola (Python)

Cliente interactivo que consume el backend Elixir vía WebSocket.

## Requisitos

- Python 3.7+
- Backend corriendo en `http://localhost:4000`

## Instalación

```bash
cd tp-final-taller
pip install -r requirements.txt
```

## Ejecución

```bash
cd tp-final-taller
python3 client.py
```

Si no tienes el backend levantado, ver pasos en [README.md](README.md).

## Flujo rápido (1 minuto)

1. Ejecutar `python3 client.py`.
2. Registrar `alice` y `bob`.
3. Login con ambos usuarios.
4. Alice agrega a Bob (opción `2`).
5. Enviar mensaje (opción `6`) y validar recepción.
6. Probar archivo (opción `12`) en `alice:bob`.

## Menú del cliente (detalle)

Pantalla inicial:
```
1. Registrarse
2. Iniciar sesión
3. Salir
```

Menú principal (logueado):
```
1. Ver contactos
2. Agregar contacto
3. Bloquear contacto
4. Ver chats
5. Crear chat grupal
6. Enviar mensaje
7. Ver mensajes de un chat
8. Buscar mensajes
9. Eliminar un mensaje
10. Eliminar múltiples mensajes
11. Ver estado de un usuario
12. Enviar archivo/imagen
13. Salir
```

## Flujo completo sugerido

1. Registrar `alice` y `bob`.
2. Loguear ambos usuarios.
3. Alice agrega a Bob (opción `2`).
4. Enviar mensaje (opción `6`) y verificar recepción.
5. Consultar historial (opción `7`) y búsqueda (opción `8`).
6. Probar borrado (opciones `9` y `10`) y estado (opción `11`).

## Envío de archivos

Opción `12`:
```
ID del chat: alice:bob
Ruta del archivo: /tmp/documento.pdf
```

Detalles técnicos:
- Límite: 5MB
- Codificación: Base64 over WebSocket
- Tipos permitidos: png, jpeg, gif, webp, pdf, txt, doc, docx, xls, xlsx

Al recibir, se muestra nombre, tipo, tamaño y URL de descarga (`/uploads/...`).

## Protocolo WebSocket (cliente)

Handshake:
- Login/registro HTTP devuelve `token`.
- El cliente abre WebSocket con `/ws?token=<auth_token>`.
- Keepalive activo (ping/pong) y reconexión automática con aviso en consola.

Formato general de acciones:
```json
{
  "action": "nombre_accion",
  "username": "usuario_actual"
}
```

Acciones usadas por el cliente:
- `get_contacts`, `add_contact`, `block_contact`
- `get_chatrooms`, `create_group_chat`, `get_status`
- `get_messages`, `send_message`, `send_file`
- `search_messages`, `delete_message`, `delete_messages`

## Troubleshooting

- **No hay conexión WebSocket activa**: verificar backend y login (token válido).
- **Error de conexión**: confirmar `http://localhost:4000`.
- **Mensajes no llegan**: verificar `chat_id` con opción `4` y participantes del chat.
- **Archivo rechazado**: revisar tamaño (<5MB) y tipo MIME permitido.

## Notas

- El cliente usa `threading` para recibir notificaciones sin bloquear la interfaz.
- Los mensajes en chats no abiertos muestran alerta visual (`🔔`) y contador de no leídos por chat/total en el menú.
- Se puede interrumpir con `Ctrl+C` de forma segura.
