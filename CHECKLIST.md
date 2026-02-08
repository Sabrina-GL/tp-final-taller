# Checklist de Implementación - TP Final

## ✅ Configuración Inicial

- [x] Proyecto Elixir estructurado
- [x] Dependencies en mix.exs actualizadas
- [x] README principal con instrucciones
- [x] README de chat_app detallado
- [x] Archivo de configuración (config/config.exs)
- [x] .gitignore mejorado
- [x] Tests básicos configurados
- [x] Documentación de arquitectura (ARQUITECTURA.md)
- [x] Guía de desarrollo (DESARROLLO.md)

## 🔄 Características Requeridas (Core)

### Alta de Usuarios
- [x] Módulo ChatApp.Accounts estructurado
- [ ] Validación de username único
- [ ] Hash de contraseñas (bcrypt_elixir)
- [ ] API REST /api/register
- [ ] Tests de registro
- [ ] Persistencia (opcional con Ecto)

### Autenticación
- [x] Módulo Accounts con authenticate_user
- [ ] Validación de credenciales
- [ ] API REST /api/login
- [ ] Tests de autenticación
- [ ] Sesiones (futuro: JWT)

### Estado de Conexión
- [x] Módulo ActivityTracker estructurado
- [ ] Rastreo de usuarios activos/inactivos
- [ ] Timestamp de última actividad
- [ ] Registry para usuarios online
- [ ] API para consultar estado
- [ ] Tests de actividad

### Lista de Contactos
- [x] Estructura en Accounts para contactos
- [ ] Agregar contactos
- [ ] Eliminar contactos
- [ ] Listar contactos
- [ ] API WebSocket para contactos
- [ ] Tests de contactos

### Chats Individuales (1-a-1)
- [x] Módulo ChatRoom estructurado
- [x] Módulo ChatManager estructurado
- [ ] Crear chat directo entre 2 usuarios
- [ ] Enviar mensajes
- [ ] Recibir mensajes en tiempo real
- [ ] Tests de chats 1-a-1

### Chats Grupales
- [ ] Crear chat grupal (>2 participantes)
- [ ] Agregar usuarios a grupo
- [ ] Remover usuarios de grupo
- [ ] Enviar mensajes en grupo
- [ ] Tests de chats grupales

### Historial de Mensajes
- [x] Almacenar últimos 10 mensajes en ChatRoom
- [ ] API para obtener historial
- [ ] Limitar a 10 mensajes por sala
- [ ] Orden cronológico correcto
- [ ] Tests de historial

### Búsqueda de Mensajes
- [x] Función search_messages en ChatManager
- [ ] Búsqueda por palabra clave
- [ ] Filtrado en historial
- [ ] API WebSocket para búsqueda
- [ ] Tests de búsqueda

### Notificaciones de Mensajes
- [ ] Mantener mensajes pendientes para usuarios offline
- [ ] Mostrar notificaciones al reconectar
- [ ] API para obtener notificaciones
- [ ] Limpiar notificaciones leídas
- [ ] Tests de notificaciones

### WebSocket
- [x] Configuración de Cowboy
- [x] SocketHandler estructurado
- [ ] Upgrade de HTTP a WebSocket
- [ ] Manejo de conexión
- [ ] Manejo de desconexión
- [ ] Parse de mensajes JSON
- [ ] Broadcast a clientes
- [ ] Tests de WebSocket

## 🎯 Características Opcionales

### Envío de Imágenes/Archivos
- [ ] Upload de archivos
- [ ] Almacenamiento de archivos
- [ ] Envío vía WebSocket
- [ ] Límite de tamaño
- [ ] Tests de archivos

### Front-end Web
- [x] Archivos HTML en priv/static/
- [ ] Mejorar interfaz
- [ ] JavaScript para WebSocket
- [ ] CSS responsive
- [ ] Tests end-to-end

### Bloquear Contactos
- [ ] API para bloquear
- [ ] Validación de bloqueos
- [ ] Prevenir mensajes de bloqueados
- [ ] Tests de bloqueos

### Borrar Mensajes
- [ ] API para borrar mensaje
- [ ] Remover de historial
- [ ] Notificar a participantes
- [ ] Tests de borrado

### Backups de Mensajes
- [ ] Persistencia en base de datos
- [ ] Configuración de Ecto
- [ ] Migrations
- [ ] Backup periódico
- [ ] Tests de persistencia

## 📋 OTP y Buenas Prácticas

### Supervisión
- [x] Application supervisor configurado
- [x] Estrategia :one_for_one
- [x] Registry para usuarios online
- [x] DynamicSupervisor para salas
- [ ] Manejo de reinicio de procesos
- [ ] Tests de supervivencia

### GenServers
- [x] Accounts como GenServer
- [x] ChatManager como GenServer
- [x] ActivityTracker como GenServer
- [x] ChatRoom como GenServer
- [ ] handle_call/handle_cast correctos
- [ ] Timeouts configurados
- [ ] Tests de GenServers

### Código Limpio
- [x] Módulos separados por responsabilidad
- [ ] Funciones documentadas con @doc
- [ ] Pattern matching usado efectivamente
- [ ] Guards para validaciones
- [ ] Código formateado (mix format)
- [ ] Sin warnings al compilar

### Testing
- [x] Estructura de tests creada
- [ ] Tests unitarios (>80%)
- [ ] Tests de integración
- [ ] Tests de concurrencia
- [ ] Coverage reportado
- [ ] Tests passing en CI (futuro)

## 📚 Documentación

- [x] README principal completo
- [x] README de chat_app
- [x] Instrucciones de instalación
- [x] Instrucciones de ejecución
- [x] Ejemplos de uso
- [x] Arquitectura documentada
- [x] Guía de desarrollo
- [ ] ExDoc generado
- [ ] Comentarios en código

## 🚀 Entrega

### Pre-entrega
- [ ] Todos los features core implementados
- [ ] Tests passing
- [ ] README completo
- [ ] Código limpio y documentado
- [ ] Demo preparada

### Demo en Vivo
- [ ] Servidor funcionando
- [ ] Registro de usuarios
- [ ] Login
- [ ] Envío de mensajes
- [ ] Búsqueda de mensajes
- [ ] Notificaciones
- [ ] Features opcionales (si aplica)

### Repositorio
- [ ] Código pusheado a GitHub
- [ ] .gitignore correcto
- [ ] Sin archivos sensibles
- [ ] Branches organizados
- [ ] Commits descriptivos

## 🐛 Testing Manual

### Escenarios de Prueba

#### 1. Registro y Login
```bash
# Escenario: Registro exitoso
- Usuario ingresa username único
- Usuario ingresa password válido
- Sistema confirma registro

# Escenario: Login exitoso
- Usuario ingresa credenciales correctas
- Sistema autentica y conecta
```

#### 2. Mensajes
```bash
# Escenario: Chat 1-a-1
- Alice y Bob registrados
- Alice inicia chat con Bob
- Alice envía mensaje
- Bob recibe mensaje en tiempo real

# Escenario: Chat grupal
- Alice, Bob, Charlie registrados
- Alice crea grupo con Bob y Charlie
- Alice envía mensaje
- Bob y Charlie reciben mensaje
```

#### 3. Búsqueda
```bash
# Escenario: Búsqueda exitosa
- Chat con varios mensajes
- Usuario busca palabra clave
- Sistema retorna mensajes relevantes
```

#### 4. Notificaciones
```bash
# Escenario: Usuario offline
- Bob está offline
- Alice envía mensaje a Bob
- Bob se conecta
- Bob ve notificación de mensaje pendiente
```

## 📊 Métricas de Calidad

- [ ] Cobertura de tests: >80%
- [ ] Warnings al compilar: 0
- [ ] Credo (linter): Aprobado
- [ ] Dialyzer: Sin errores
- [ ] ExDoc: Generado sin errores
- [ ] Performance: <100ms latencia

## 🎓 Criterios de Evaluación

- [ ] **Correcto uso de OTP**: Supervisores, GenServers, Registry
- [ ] **Funcionalidad**: Todas las features core funcionan
- [ ] **Código limpio**: Modular, legible, bien organizado
- [ ] **Tests**: Unitarios e integración básicos
- [ ] **Documentación**: README claro, instrucciones completas
- [ ] **Demo**: Funcionalidad demostrada en vivo

---

## 📝 Notas de Progreso

### Completado
- ✅ Estructura del proyecto
- ✅ Configuración inicial
- ✅ Documentación base
- ✅ Tests estructurados

### En Progreso
- 🔄 Implementación de features core

### Pendiente
- ⏳ Features opcionales
- ⏳ Tests exhaustivos
- ⏳ Demo final

---

**Última actualización**: Febrero 2026
**Grupo**: [Nombre del grupo]
**Integrantes**: [Nombres]
