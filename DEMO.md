# 🎬 Demo del Proyecto - TP Final

## Pasos para la Demostración

### Preparación (5 minutos antes)

1. **Verificar instalación**:
```bash
cd tp-final-taller
elixir --version  # Verificar Elixir
python3 --version # Verificar Python
```

2. **Instalar dependencias**:
```bash
# Backend
cd chat_app
mix deps.get

# Cliente
cd ..
pip install -r requirements.txt
```

### Demo en Vivo

#### Terminal 1: Servidor
```bash
cd chat_app
iex -S mix
```

Esperar a ver: `💬 Chat application started on port 4000`

#### Terminal 2: Cliente Alice
```bash
./demo_client.sh
```

**Flujo de demostración**:
1. Registrar: `alice` / `alice123`
2. Login: `alice` / `alice123`
3. Esperar a conectar (verás "✅ Login exitoso")

#### Terminal 3: Cliente Bob (simultáneo)
```bash
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
→ Mostrará: chat_alice_bob (creado automáticamente)
```

#### 3. Enviar mensaje (Alice → Bob)
```
Opción: 5 (Enviar mensaje)
ID del chat: chat_alice_bob
Mensaje: Hola Bob, cómo estás?
→ Bob recibirá notificación inmediata
```

#### 4. Ver mensajes (Bob)
```
Opción: 6 (Ver mensajes)
ID del chat: chat_alice_bob
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
Opción: 9 (Salir)
```

#### 8. Enviar mensaje mientras Bob offline (Alice)
```
Opción: 5
ID: chat_alice_bob
Mensaje: ¿Listo para la reunión?
```

#### 9. Reconectar Bob
```
Login nuevamente como bob
→ Recibirás automáticamente los mensajes pendientes (cola offline)
```

#### 10. Buscar mensajes (Bob)
```
Opción: 7 (Buscar)
ID del chat: chat_alice_bob
Palabra: reunión
→ Encontrará el mensaje de Alice
```

### Features Demostradas ✅

- ✅ Alta de usuarios con validación
- ✅ Autenticación
- ✅ Estado de conexión (online/offline/last_seen)
- ✅ Lista de contactos
- ✅ Chats 1-a-1 (automáticos al agregar contacto)
- ✅ Chats grupales
- ✅ Últimos 10 mensajes
- ✅ Búsqueda por keyword
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
cd chat_app
mix test
```
→ Mostrará: 59 tests, 74.68% cobertura, todos ✅

### Troubleshooting Durante la Demo

**Error: "No hay conexión WebSocket"**
- Verificar que el servidor esté corriendo
- Reiniciar el cliente

**Error: "Usuario ya existe"**
- Usar otros nombres: carol, dave, eve, etc.

**No llegan notificaciones**
- Verificar que ambos clientes estén conectados
- Revisar que el room_id sea correcto (usar "Ver chats" primero)

### Puntos Clave a Destacar

1. **OTP completo**: Supervision tree, GenServers, Registries
2. **WebSocket bidireccional**: Cliente ↔ Servidor
3. **Notificaciones real-time**: Sin polling
4. **26Cola offline inteligente**: Guarda y entrega al reconectar
5. **Tests robustos**: 74.68% cobertura
6. **Cliente por consola funcional**: Todas las features accesibles

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
