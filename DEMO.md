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

#### 1. Contactos (Alice)
```
Opción: 2 (Agregar contacto)
Usuario: bob
→ Verás confirmación en ambos terminales
```

#### 2. Ver chats creados (Alice)
```
Opción: 3 (Ver chats)
→ Mostrará: alice:bob (creado automáticamente)
```

#### 3. Enviar mensaje (Alice → Bob)
```
Opción: 5 (Enviar mensaje)
ID del chat: alice:bob
Mensaje: Hola Bob, cómo estás?
→ Bob recibirá notificación inmediata
```

#### 4. Ver mensajes (Bob)
```
Opción: 6 (Ver mensajes)
ID del chat: alice:bob
→ Mostrará el mensaje de Alice
```

#### 5. Chat grupal (Bob)
```
Opción: 4 (Crear grupo)
Nombre: equipo
Participantes: alice, charlie
→ Notificaciones a todos los participantes
```

#### 6. Estado de usuario (Alice)
```
Opción: 8 (Ver estado)
Usuario: bob
→ Mostrará: online, last_seen
```

#### 7. Desconectar Bob
```
Opción: 12 (Salir)
```

#### 8. Enviar mensaje mientras Bob offline (Alice)
```
Opción: 6
ID: alice:bob
Mensaje: ¿Listo para la reunión?
```

#### 9. Reconectar Bob
```
Login nuevamente como bob
→ Recibirás automáticamente los mensajes pendientes (cola offline)
```

#### 10. Bloquear contacto (Bob bloquea Alice)
```
Opción: 3
Usuario a bloquear: alice
🚫 Bloqueando a: alice
```

#### 11. Eliminar mensaje (Alice)
```
Opción: 9
ID del chat: alice:bob
ID del mensaje a eliminar: 1
→ El mensaje se elimina de la BD y memoria
```

### Features Demostradas ✅

- ✅ Alta de usuarios con validación
- ✅ Autenticación
- ✅ Estado de conexión (online/offline/last_seen)
- ✅ Lista de contactos
- ✅ **Bloqueo de contactos (bidireccional)**
- ✅ Chats 1-a-1 (automáticos al agregar contacto)
- ✅ Chats grupales
- ✅ Últimos 10 mensajes
- ✅ Búsqueda por keyword
- ✅ **Eliminación de mensajes (simple y lote)**
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
→ Mostrará: 133 tests, 85.12% cobertura, todos ✅

### Troubleshooting Durante la Demo

**Error: "No hay conexión WebSocket"**
- Verificar que el servidor esté corriendo
- Reiniciar el cliente

**Error: "Usuario ya existe"**
- Usar otros nombres: carol, dave, eve, etc.

**Error: `no such table: contacts` (o tablas faltantes)**
- Si estás usando Docker: `make docker-reset`
- Si estás en local: en `chat_app/` ejecutar `mix ecto.create && mix ecto.migrate`
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
5. **Tests robustos**: 85.12% cobertura
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
