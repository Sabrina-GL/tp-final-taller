# 🎬 Demo del Proyecto - TP Final

## Pasos para la Demostración

### Preparación (5 minutos antes)

1. **Verificar instalación**:
```bash
cd tp-final-taller
elixir --version  # Verificar Elixir
python3 --version # Verificar Python
make help         # Ver comandos disponibles
```

2. **Setup inicial Docker** (primera vez solamente):
```bash
make setup-docker              # agrega usuario a grupo docker
newgrp docker                  # activa grupo sin relogin
make setup-dockerized          # levanta backend en contenedor
pip install -r requirements.txt
```

**Alternativa sin reiniciar sesión:**
```bash
make setup-docker
make setup-dockerized-sudo     # usa sudo directamente
pip install -r requirements.txt
```

3. **Preparar BD limpia** (justo antes de demostrar):
```bash
make docker-reset              # reinicia contenedores y volumenes
# O si tienes problemas de permisos: make docker-reset-sudo
```

Alternativa local (sin Docker): `make setup && make demo-setup`
Requiere Postgres local corriendo (por defecto `localhost:5432`) y variables `POSTGRES_*`
si no usas los valores por defecto (`postgres/postgres`, DB `chat_app_dev`).

### Demo en Vivo

#### Terminal 1: Servidor
```bash
cd tp-final-taller
make docker-status
make docker-logs
```

Esperar a ver: `💬 Chat application started on port 4000`

#### Terminal 2: Cliente Alice
```bash
cd tp-final-taller
./demo_client.sh
```

**Flujo de demostración**:
1. Registrar: `alice` / `alice123`
2. Login: `alice` / `alice123`
3. Esperar a conectar (verás "✅ Login exitoso")

#### Terminal 3: Cliente Bob (simultáneo)
```bash
cd tp-final-taller
python3 client.py
```

**Flujo**:
1. Registrar: `bob` / `bob123456`
2. Login: `bob` / `bob123456`

### Escenario de Demo Sugerido

**Mostrar todas las features obligatorias**:

#### 1. Ver contactos (Alice)
```
Opción: 1 (Ver contactos)
→ Lista vacía inicialmente
```

#### 2. Agregar contacto (Alice)
```
Opción: 2 (Agregar contacto)
Usuario: bob
→ Verás confirmación en ambos terminales
→ Se crea automáticamente chat alice:bob
```

#### 3. Ver chats creados (Alice)
```
Opción: 4 (Ver chats)
→ Mostrará: alice:bob (creado automáticamente)
```

#### 4. Enviar mensaje (Alice → Bob)
```
Opción: 6 (Enviar mensaje)
ID del chat: alice:bob
Mensaje: Hola Bob, cómo estás?
→ Bob recibirá notificación inmediata
```

#### 5. Ver mensajes (Bob)
```
Opción: 7 (Ver mensajes de un chat)
ID del chat: alice:bob
→ Mostrará el mensaje de Alice
```

#### 6. Chat grupal (Bob)
```
Opción: 5 (Crear chat grupal)
Nombre: equipo
Participantes: alice
→ Notificaciones a todos los participantes
```

#### 7. Buscar mensajes en un chat (Bob)
```
Opción: 8 (Buscar mensajes en un chat)
ID del chat: alice:bob
Palabra clave: Hola
→ Mostrará mensajes que contengan "Hola"
```

#### 8. Ver estado de usuario (Alice)
```
Opción: 11 (Ver estado de un usuario)
Usuario: bob
→ Mostrará: online, last_seen, blocked_by (si aplica)
```

#### 9. Bloquear contacto (Bob bloquea Alice)
```
Opción: 3 (Bloquear contacto)
Usuario a bloquear: alice
→ 🚫 alice ha sido bloqueado/a
→ Alice no podrá enviar mensajes a Bob
```

#### 10. Eliminar un mensaje (Alice)
```
Opción: 9 (Eliminar un mensaje)
ID del chat: alice:bob
ID del mensaje a eliminar: 1
→ El mensaje se elimina de la BD y memoria
```

#### 11. Enviar múltiples mensajes para luego eliminarlos (Alice)
```
Opción: 6 (Enviar mensaje)
Envía 3 mensajes diferentes en el chat alice:bob
→ Nota los IDs de cada mensaje
```

#### 12. Eliminar múltiples mensajes (Alice)
```
Opción: 10 (Eliminar múltiples mensajes)
ID del chat: alice:bob
IDs de mensajes (separados por coma): 2,3,4
→ Los mensajes se eliminan de forma lote
```

#### 13. Desconectar Bob
```
Opción: 12 (Salir)
```

#### 14. Enviar mensaje mientras Bob offline (Alice)
```
Opción: 6 (Enviar mensaje)
ID: alice:bob
Mensaje: ¿Listo para la reunión?
→ El mensaje se guarda en cola offline
```

#### 15. Reconectar Bob
```
Login nuevamente como bob
→ Recibirás automáticamente los mensajes pendientes (cola offline)
```

### Features Demostradas ✅

- ✅ Alta de usuarios con validación
- ✅ Autenticación
- ✅ Estado de conexión (online/offline/last_seen)
- ✅ Lista de contactos
- ✅ **Bloqueo de contactos (bidireccional)** - Opción 3
- ✅ Chats 1-a-1 (automáticos al agregar contacto)
- ✅ Chats grupales - Opción 5
- ✅ Últimos 10 mensajes - Opción 7
- ✅ Búsqueda por keyword - Opción 8
- ✅ **Eliminación de mensajes (simple y lote)** - Opciones 9 y 10
- ✅ Notificaciones en tiempo real
- ✅ Cola de notificaciones offline

### Pruebas Adicionales (si hay tiempo)

#### Frontend Web
```bash
# En navegador
http://localhost:4000
```
- Registrar usuario desde web
- Interactuar con usuarios del CLI

#### Tests
```bash
cd tp-final-taller
make test
```
→ Debe finalizar sin failures

Para cobertura:
```bash
cd chat_app
mix test --cover
```

### Troubleshooting Durante la Demo

**Error: "No hay conexión WebSocket"**
- Verificar que el servidor esté corriendo
- Reiniciar el cliente

**Error: "Usuario ya existe"**
- Usar otros nombres: carol, dave, eve, etc.

**Error: `relation "contacts" does not exist` (o tablas faltantes)**
- Si estás usando Docker: `make docker-reset`
- Si estás en local: en `chat_app/` ejecutar `mix ecto.drop && mix ecto.create && mix ecto.migrate`
- Reiniciar servidor

**Error Docker: `permission denied /var/run/docker.sock`**
- Solución 1: Activar grupo docker → `newgrp docker` y reintentar
- Solución 2: Usar comandos con sudo → `make setup-dockerized-sudo`, `make docker-logs-sudo`
- Solución 3 (permanente): Ejecutar `make setup-docker`, cerrar sesión y volver a entrar

**Error: "Missing user" en WebSocket**
- Este error significa que el cliente no pasó el usuario en la URL del WebSocket
- Solución: El cliente.py debe conectar a `ws://localhost:4000/ws?user=<username>`
- ✅ YA ESTÁ CORREGIDO en la última versión del código
- Si aún aparece: Garantizar que `client.py` tenga la línea: `ws_url = f"{self.ws_url}?user={self.username}"`

**No llegan notificaciones**
- Verificar que ambos clientes estén conectados
- Revisar que el room_id sea correcto (usar "Ver chats" primero)

### Puntos Clave a Destacar

1. **OTP completo**: Supervision tree, GenServers, Registries
2. **WebSocket bidireccional**: Cliente ↔ Servidor
3. **Notificaciones real-time**: Sin polling
4. **Cola offline inteligente**: Guarda y entrega al reconectar
5. **Tests robustos**: suite automatizada + cobertura ejecutable con `mix test --cover`
6. **Cliente por consola funcional**: Todas las features accesibles

---

## 🌐 ALTERNATIVA: Demo con Cliente Web

Si prefieres demostrar con la interfaz web (sin cliente Python), es más simple:

### Preparación

```bash
cd tp-final-taller
make dev
```

Esperar a: `💬 Chat application started on port 4000`

### Demostración en Navegador

Abre dos navegadores en:
```
http://localhost:4000
```

**Usuario 1 (Alice)**:
1. Click "Register"
2. Usuario: `alice`, Password: `alice123`
3. Submit → Login automático

**Usuario 2 (Bob)**  - En otra ventana:
1. Click "Register"
2. Usuario: `bob`, Password: `bob123456`
3. Submit → Login automático

### Flujo Demo Web

**Paso 1: Ver Contactos (Alice)**
- Click en el icono 👥 (Contacts)
- Mostrará lista vacía

**Paso 2: Agregar Contacto (Alice)**
- Campo "Nuevo contacto" → Escribe "bob" → Enter
- Bob recibe notificación automática

**Paso 3: Ver Chats (Alice)**
- Click en icono 💬 (Chats)
- Mostrará chat "alice:bob" creado automáticamente

**Paso 4: Enviar Mensaje (Alice)**
- Click en chat "alice:bob"
- Campo texto → "Hola Bob, ¿cómo estás?" → Enter
- Bob lo recibe en tiempo real

**Paso 5: Ver Estado**
- Click en usuario Bob en lista de contactos
- Mostrará: "online" + timestamp de conexión

**Paso 6: Chat Grupal (Bob)**
- Click en "+ New Group"
- Nombre: "equipo"
- Participantes: alice
- Crear → Notificación a Alice inmediata

### Ventajas del Cliente Web
- ✅ Visual y fácil de seguir
- ✅ Interfaz gráfica clara
- ✅ Notificaciones integradas
- ✅ Búsqueda visible
- ✅ Historial de mensajes

### Archivo de Log de Demo

Si quieres grabar la demo:
```bash
script -c "./demo_client.sh" demo_output.txt
```

Esto guardará toda la interacción en `demo_output.txt`.

## 📝 Checklist Pre-Demo

- [ ] Servidor Elixir compilando sin errores
- [ ] Cliente Python ejecutable (`chmod +x`)
- [ ] Dependencias instaladas (websocket-client, requests)
- [ ] Puerto 4000 libre
- [ ] Tests pasando (opcional pero recomendado)
- [ ] README actualizado con instrucciones
- [ ] Dos terminales abiertas listas

## 🎯 Timing Sugerido (15 minutos)

- **0-2 min**: Mostrar estructura del proyecto + documentación
- **2-5 min**: Iniciar servidor + explicar arquitectura OTP
- **5-12 min**: Demo interactiva con 2 clientes (escenario completo)
- **12-14 min**: Mostrar tests + cobertura
- **14-15 min**: Preguntas
