.PHONY: help dev dev-docker test demo-smoke compile deps setup setup-dockerized setup-dockerized-sudo demo db-reset db-clean demo-setup db-backup-docker db-restore-docker db-backup-local db-restore-local db-backup-verify-docker clean mrproper reset-all docker-up docker-down docker-logs docker-status docker-refresh-app docker-refresh-app-sudo docker-reset docker-up-sudo docker-down-sudo docker-status-sudo docker-logs-sudo docker-reset-sudo setup-docker

# Color para output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help:
	# Muestra el listado de comandos disponibles y su propósito.
	@echo "$(CYAN)🎬 Chat App - Comandos Disponibles$(NC)"
	@echo ""
	@echo "$(GREEN)Desarrollo$(NC)"
	@echo "  make dev              Inicia servidor (iex -S mix)"
	@echo "  make dev-docker       Inicia app en Docker en foreground"
	@echo "  make compile          Compila el proyecto"
	@echo "  make deps             Instala dependencias"
	@echo "  make setup            Setup rápido (deps + pip + db-reset)"
	@echo "  make setup-dockerized Setup rápido con Docker (up + status)"
	@echo "  make setup-dockerized-sudo Setup Docker usando sudo"
	@echo "  make demo             Setup demo + pasos siguientes"
	@echo ""
	@echo "$(GREEN)Testing$(NC)"
	@echo "  make test             Ejecuta tests (172 tests)"
	@echo "  make demo-smoke       Valida demo automáticamente (login + WS + chat + archivo + offline)"
	@echo "  make test-watch       Ejecuta tests en modo watch"
	@echo ""
	@echo "$(GREEN)Base de Datos$(NC)"
	@echo "  make db-reset         Reinicia BD PostgreSQL (drop + create + migrate)"
	@echo "  make db-clean         Elimina BD PostgreSQL de desarrollo"
	@echo "  make db-backup-docker Backup PostgreSQL (Docker) en backups/postgres/"
	@echo "  make db-restore-docker FILE=... Restaura dump en DB (por defecto chat_app_restore)"
	@echo "  make db-backup-local  Backup PostgreSQL local (sin Docker)"
	@echo "  make db-restore-local FILE=... Restaura dump local en DB separada"
	@echo "  make db-backup-verify-docker Prueba rápida de backup + restore"
	@echo "  make demo-setup       Prepara BD para demo con instrucciones"
	@echo ""
	@echo "$(GREEN)Docker (opcional)$(NC)"
	@echo "  make docker-up        Levanta servicios de docker-compose"
	@echo "  make docker-down      Baja servicios de docker-compose"
	@echo "  make docker-status    Estado de servicios docker-compose"
	@echo "  make docker-logs      Logs de servicios docker-compose"
	@echo "  make docker-refresh-app Rebuild/restart solo chat_app (rápido)"
	@echo "  make docker-refresh-app-sudo Igual que docker-refresh-app usando sudo"
	@echo "  make docker-reset     Reinicia contenedores y volumenes de compose"
	@echo "  make docker-up-sudo   Levanta compose usando sudo"
	@echo "  make docker-status-sudo Estado compose usando sudo"
	@echo "  make setup-docker     Configura permisos para usar docker sin sudo"
	@echo ""
	@echo "$(GREEN)Limpieza$(NC)"
	@echo "  make clean            Limpia artifacts (_build, .mix, etc)"
	@echo "  make mrproper         Limpia TODO (deps, artifacts, BD)"
	@echo "  make reset-all        Reinicio total (docker + Postgres + build + caches)"
	@echo ""

# Desarrollo
dev:
	# Inicia el servidor local de Elixir en modo interactivo.
	@cd chat_app && iex -S mix

dev-docker:
	# Levanta la app con Docker Compose en primer plano.
	@docker compose up --build

compile:
	# Compila el proyecto Elixir y valida que no haya errores de build.
	@cd chat_app && mix compile

deps:
	# Descarga e instala dependencias de Elixir.
	@cd chat_app && mix deps.get

setup: deps
	# Setup rápido: instala deps Python y resetea la base de datos de desarrollo.
	@pip install -r requirements.txt
	@$(MAKE) db-reset
	@echo "$(GREEN)✓ Setup completado (Elixir + Python + BD limpia)$(NC)"

setup-dockerized:
	# Setup rápido usando Docker sin sudo (levanta y muestra estado).
	@$(MAKE) docker-up
	@$(MAKE) docker-status
	@echo "$(GREEN)✓ Setup Docker completado$(NC)"

setup-dockerized-sudo:
	# Setup rápido usando Docker con sudo (levanta y muestra estado).
	@$(MAKE) docker-up-sudo
	@$(MAKE) docker-status-sudo
	@echo "$(GREEN)✓ Setup Docker completado (sudo)$(NC)"

demo: demo-setup
	# Prepara la demo y confirma que el entorno quedó listo.
	@echo "$(GREEN)✓ Demo lista para iniciar$(NC)"

# Testing
test:
	# Ejecuta toda la suite de tests de Elixir.
	@cd chat_app && mix test

demo-smoke:
	# Ejecuta validación automática de la demo de punta a punta.
	@python3 scripts/demo_smoke.py

test-watch:
	# Ejecuta tests en modo escucha para re-ejecución interactiva.
	@cd chat_app && mix test --listen-on-stdin

# Base de Datos
db-reset:
	# Resetea la BD de desarrollo: drop + create + migrate.
	@cd chat_app && \
	echo "$(YELLOW)🗑️  Eliminando BD PostgreSQL (si existe)...$(NC)" && \
	MIX_ENV=dev mix ecto.drop || true && \
	echo "$(YELLOW)✨ Creando BD PostgreSQL...$(NC)" && \
	mix ecto.create && \
	echo "$(YELLOW)🚀 Migrando esquema...$(NC)" && \
	mix ecto.migrate && \
	echo "$(GREEN)✓ BD lista para usar$(NC)"

db-clean:
	# Elimina únicamente la BD de desarrollo.
	@cd chat_app && MIX_ENV=dev mix ecto.drop || true
	@echo "$(GREEN)✓ BD de desarrollo eliminada$(NC)"

db-backup-docker:
	# Genera backup de PostgreSQL en Docker y mantiene los 7 más recientes.
	@mkdir -p backups/postgres
	@FILE=backups/postgres/chat_app_dev_$$(date +%Y%m%d_%H%M%S).dump; \
	(echo "$(YELLOW)📦 Generando backup Docker en $$FILE...$(NC)" && \
	((docker exec -e PGPASSWORD=postgres chat_postgres pg_dump -U postgres -d chat_app_dev -Fc --no-owner --no-privileges > "$$FILE") || \
	 (sudo docker exec -e PGPASSWORD=postgres chat_postgres pg_dump -U postgres -d chat_app_dev -Fc --no-owner --no-privileges > "$$FILE"))) && \
	echo "$(GREEN)✓ Backup generado: $$FILE$(NC)" && \
	ls -1t backups/postgres/chat_app_dev_*.dump 2>/dev/null | tail -n +8 | xargs -r rm -f

db-restore-docker:
	# Restaura un dump en una BD Docker (por defecto chat_app_restore).
	@test -n "$(FILE)" || (echo "Uso: make db-restore-docker FILE=backups/postgres/<archivo.dump> [RESTORE_DB=chat_app_restore]" && exit 1)
	@test -f "$(FILE)" || (echo "Archivo no encontrado: $(FILE)" && exit 1)
	@DB_NAME=$${RESTORE_DB:-chat_app_restore}; \
	echo "$(YELLOW)♻️ Restaurando $(FILE) en $$DB_NAME...$(NC)" && \
	((docker exec -e PGPASSWORD=postgres chat_postgres createdb -U postgres $$DB_NAME 2>/dev/null || true) || \
	 (sudo docker exec -e PGPASSWORD=postgres chat_postgres createdb -U postgres $$DB_NAME 2>/dev/null || true)) && \
	((cat "$(FILE)" | docker exec -i -e PGPASSWORD=postgres chat_postgres pg_restore -U postgres -d $$DB_NAME --clean --if-exists --no-owner --no-privileges) || \
	 (cat "$(FILE)" | sudo docker exec -i -e PGPASSWORD=postgres chat_postgres pg_restore -U postgres -d $$DB_NAME --clean --if-exists --no-owner --no-privileges)) && \
	echo "$(GREEN)✓ Restore completado en $$DB_NAME$(NC)"

db-backup-local:
	# Genera backup de PostgreSQL local y mantiene los 7 más recientes.
	@mkdir -p backups/postgres
	@FILE=backups/postgres/chat_app_dev_$$(date +%Y%m%d_%H%M%S).dump; \
	echo "$(YELLOW)📦 Generando backup local en $$FILE...$(NC)" && \
	PGPASSWORD=postgres pg_dump -h localhost -p 5432 -U postgres -d chat_app_dev -Fc --no-owner --no-privileges > "$$FILE" && \
	echo "$(GREEN)✓ Backup generado: $$FILE$(NC)" && \
	ls -1t backups/postgres/chat_app_dev_*.dump 2>/dev/null | tail -n +8 | xargs -r rm -f

db-restore-local:
	# Restaura un dump en una BD local separada.
	@test -n "$(FILE)" || (echo "Uso: make db-restore-local FILE=backups/postgres/<archivo.dump> [RESTORE_DB=chat_app_restore]" && exit 1)
	@test -f "$(FILE)" || (echo "Archivo no encontrado: $(FILE)" && exit 1)
	@DB_NAME=$${RESTORE_DB:-chat_app_restore}; \
	echo "$(YELLOW)♻️ Restaurando $(FILE) en $$DB_NAME (local)...$(NC)" && \
	PGPASSWORD=postgres createdb -h localhost -p 5432 -U postgres $$DB_NAME 2>/dev/null || true; \
	PGPASSWORD=postgres pg_restore -h localhost -p 5432 -U postgres -d $$DB_NAME --clean --if-exists --no-owner --no-privileges "$(FILE)" && \
	echo "$(GREEN)✓ Restore completado en $$DB_NAME$(NC)"

db-backup-verify-docker:
	# Ejecuta backup + restore de prueba y valida consulta básica en messages.
	@$(MAKE) db-backup-docker
	@LATEST=$$(ls -1t backups/postgres/chat_app_dev_*.dump | head -n 1); \
	echo "$(YELLOW)🧪 Verificando backup con restore de $$LATEST...$(NC)"; \
	$(MAKE) db-restore-docker FILE=$$LATEST RESTORE_DB=chat_app_restore_verify; \
	((docker exec -e PGPASSWORD=postgres chat_postgres psql -U postgres -d chat_app_restore_verify -t -c "SELECT COUNT(*) FROM messages;" >/dev/null) || \
	 (sudo docker exec -e PGPASSWORD=postgres chat_postgres psql -U postgres -d chat_app_restore_verify -t -c "SELECT COUNT(*) FROM messages;" >/dev/null)) && \
	echo "$(GREEN)✓ Verificación OK: restore consultable (tabla messages accesible)$(NC)"

demo-setup: db-reset
	# Deja la BD limpia y muestra guía rápida para correr la demo.
	@echo ""
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@echo "$(GREEN)✓ BD limpia y lista para DEMO$(NC)"
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Próximos pasos:$(NC)"
	@echo "  1. Terminal 1 (Servidor):"
	@echo "     $(CYAN)make dev$(NC)"
	@echo ""
	@echo "  2. Terminal 2 (Cliente Alice):"
	@echo "     $(CYAN)cd tp-final-taller && ./demo_client.sh$(NC)"
	@echo ""
	@echo "  3. Terminal 3 (Cliente Bob):"
	@echo "     $(CYAN)cd tp-final-taller && python3 client.py$(NC)"
	@echo ""
	@echo "$(YELLOW)Ver guía completa en:$(NC)"
	@echo "  $(CYAN)cat DEMO.md$(NC)"
	@echo ""

# Limpieza
clean:
	# Limpia artefactos de compilación y dependencias locales de Elixir.
	@cd chat_app && \
	echo "$(YELLOW)🧹 Limpiando artifacts...$(NC)" && \
	mix clean && \
	rm -rf _build deps .mix && \
	echo "$(GREEN)✓ Limpieza completada$(NC)"

mrproper: clean db-clean
	# Limpieza profunda: artifacts + dependencias + BD de desarrollo.
	@echo "$(GREEN)✓ Limpieza total completada (incluyendo deps y BD)$(NC)"
	@echo "$(YELLOW)Ejecuta 'make deps' para reinstalar dependencias$(NC)"

reset-all:
	# Reinicio total del proyecto (Docker, BDs dev/test, caches y builds).
	@echo "$(YELLOW)♻️  Reinicio total del proyecto...$(NC)"
	@docker compose down -v >/dev/null 2>&1 || echo "$(YELLOW)⚠️  No se pudo bajar docker (permiso o no estaba levantado).$(NC)"
	@cd chat_app && MIX_ENV=dev mix ecto.drop || true
	@cd chat_app && MIX_ENV=test mix ecto.drop || true
	@rm -rf chat_app/_build chat_app/.mix __pycache__ .pytest_cache
	@find . -type d -name "__pycache__" -prune -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✓ Reset completo terminado$(NC)"
	@echo "$(YELLOW)Siguiente paso sugerido: make setup-dockerized$(NC)"

docker-up:
	# Levanta servicios de docker-compose en segundo plano.
	@docker compose up -d || sg docker -c "docker compose up -d" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make setup-dockerized-sudo$(NC)" && exit 1)

docker-down:
	# Baja servicios de docker-compose.
	@docker compose down || sg docker -c "docker compose down" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make docker-down-sudo$(NC)" && exit 1)

docker-logs:
	# Muestra logs en vivo de los servicios de docker-compose.
	@docker compose logs -f || sg docker -c "docker compose logs -f" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make docker-logs-sudo$(NC)" && exit 1)

docker-status:
	# Muestra estado actual de contenedores de docker-compose.
	@docker compose ps || sg docker -c "docker compose ps" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make docker-status-sudo$(NC)" && exit 1)

docker-refresh-app:
	# Rebuild y restart solo del servicio chat_app (sin tocar Postgres/volúmenes).
	@docker compose up -d --build chat_app || sg docker -c "docker compose up -d --build chat_app" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make docker-reset-sudo$(NC)" && exit 1)

docker-refresh-app-sudo:
	# Rebuild y restart solo del servicio chat_app usando sudo.
	@sudo docker compose up -d --build chat_app

docker-reset:
	# Reinicia entorno Docker: baja con volúmenes y vuelve a construir/levantar.
	@docker compose down -v || sg docker -c "docker compose down -v" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make docker-reset-sudo$(NC)" && exit 1)
	@docker compose up -d --build || sg docker -c "docker compose up -d --build" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make docker-reset-sudo$(NC)" && exit 1)

docker-up-sudo:
	# Levanta servicios de docker-compose usando sudo.
	@sudo docker compose up -d

docker-down-sudo:
	# Baja servicios de docker-compose usando sudo.
	@sudo docker compose down

docker-status-sudo:
	# Muestra estado de docker-compose usando sudo.
	@sudo docker compose ps

docker-logs-sudo:
	# Muestra logs en vivo de docker-compose usando sudo.
	@sudo docker compose logs -f

docker-reset-sudo:
	# Reinicia entorno Docker (down -v + up --build) usando sudo.
	@sudo docker compose down -v
	@sudo docker compose up -d --build

setup-docker:
	# Agrega el usuario al grupo docker para evitar usar sudo.
	@echo "$(YELLOW)Agregando usuario al grupo docker...$(NC)"
	@sudo usermod -aG docker $$USER
	@echo "$(GREEN)✓ Completado.$(NC)"
	@echo "$(YELLOW)Opciones para aplicar cambios:$(NC)"
	@echo "  1) Cerrar sesión y volver a entrar (recomendado)"
	@echo "  2) Ejecutar ahora: newgrp docker"