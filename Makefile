.PHONY: help dev dev-docker test compile deps setup setup-dockerized setup-dockerized-sudo demo db-reset db-clean demo-setup clean mrproper reset-all docker-up docker-down docker-logs docker-status docker-reset docker-up-sudo docker-down-sudo docker-status-sudo docker-logs-sudo docker-reset-sudo setup-docker

# Color para output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help:
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
	@echo "  make test             Ejecuta tests (133 tests)"
	@echo "  make test-watch       Ejecuta tests en modo watch"
	@echo ""
	@echo "$(GREEN)Base de Datos$(NC)"
	@echo "  make db-reset         Limpia BD, crea nueva y migra (prepara para demo)"
	@echo "  make db-clean         Solo elimina archivo chat_app_dev.db"
	@echo "  make demo-setup       Prepara BD para demo con instrucciones"
	@echo ""
	@echo "$(GREEN)Docker (opcional)$(NC)"
	@echo "  make docker-up        Levanta servicios de docker-compose"
	@echo "  make docker-down      Baja servicios de docker-compose"
	@echo "  make docker-status    Estado de servicios docker-compose"
	@echo "  make docker-logs      Logs de servicios docker-compose"
	@echo "  make docker-reset     Reinicia contenedores y volumenes de compose"
	@echo "  make docker-up-sudo   Levanta compose usando sudo"
	@echo "  make docker-status-sudo Estado compose usando sudo"
	@echo "  make setup-docker     Configura permisos para usar docker sin sudo"
	@echo ""
	@echo "$(GREEN)Limpieza$(NC)"
	@echo "  make clean            Limpia artifacts (_build, .mix, etc)"
	@echo "  make mrproper         Limpia TODO (deps, artifacts, BD)"
	@echo "  make reset-all        Reinicio total (docker + SQLite + build + caches)"
	@echo ""

# Desarrollo
dev:
	@cd chat_app && iex -S mix

dev-docker:
	@docker compose up --build

compile:
	@cd chat_app && mix compile

deps:
	@cd chat_app && mix deps.get

setup: deps
	@pip install -r requirements.txt
	@$(MAKE) db-reset
	@echo "$(GREEN)✓ Setup completado (Elixir + Python + BD limpia)$(NC)"

setup-dockerized:
	@$(MAKE) docker-up
	@$(MAKE) docker-status
	@echo "$(GREEN)✓ Setup Docker completado$(NC)"

setup-dockerized-sudo:
	@$(MAKE) docker-up-sudo
	@$(MAKE) docker-status-sudo
	@echo "$(GREEN)✓ Setup Docker completado (sudo)$(NC)"

demo: demo-setup
	@echo "$(GREEN)✓ Demo lista para iniciar$(NC)"

# Testing
test:
	@cd chat_app && mix test

test-watch:
	@cd chat_app && mix test --listen-on-stdin

# Base de Datos
db-reset:
	@if command -v lsof >/dev/null 2>&1 && lsof /home/michael/Documentos/Facultad/Taller/tp-final-taller/chat_app/chat_app_dev.db >/dev/null 2>&1; then \
		echo "$(YELLOW)⚠️  La BD está en uso por otro proceso.$(NC)"; \
		echo "$(YELLOW)   Detén el servidor (Ctrl+C) y vuelve a ejecutar: make db-reset$(NC)"; \
		exit 1; \
	fi
	@cd chat_app && \
	echo "$(YELLOW)🗑️  Eliminando BD antigua...$(NC)" && \
	rm -f chat_app_dev.db chat_app_dev.db-shm chat_app_dev.db-wal && \
	echo "$(YELLOW)✨ Creando BD nueva...$(NC)" && \
	mix ecto.create && \
	echo "$(YELLOW)🚀 Migrando esquema...$(NC)" && \
	mix ecto.migrate && \
	echo "$(GREEN)✓ BD lista para usar$(NC)"

db-clean:
	@cd chat_app && rm -f chat_app_dev.db && echo "$(GREEN)✓ chat_app_dev.db eliminado$(NC)"

demo-setup: db-reset
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
	@cd chat_app && \
	echo "$(YELLOW)🧹 Limpiando artifacts...$(NC)" && \
	mix clean && \
	rm -rf _build deps .mix && \
	echo "$(GREEN)✓ Limpieza completada$(NC)"

mrproper: clean db-clean
	@echo "$(GREEN)✓ Limpieza total completada (incluyendo deps y BD)$(NC)"
	@echo "$(YELLOW)Ejecuta 'make deps' para reinstalar dependencias$(NC)"

reset-all:
	@echo "$(YELLOW)♻️  Reinicio total del proyecto...$(NC)"
	@if command -v lsof >/dev/null 2>&1 && lsof /home/michael/Documentos/Facultad/Taller/tp-final-taller/chat_app/chat_app_dev.db >/dev/null 2>&1; then \
		echo "$(YELLOW)⚠️  Detecté la BD en uso. Cerrá el servidor (Ctrl+C) y vuelve a ejecutar make reset-all.$(NC)"; \
		exit 1; \
	fi
	@docker compose down -v >/dev/null 2>&1 || echo "$(YELLOW)⚠️  No se pudo bajar docker (permiso o no estaba levantado).$(NC)"
	@cd chat_app && rm -f chat_app_dev.db chat_app_dev.db-shm chat_app_dev.db-wal chat_app_test.db
	@rm -rf chat_app/_build chat_app/.mix __pycache__ .pytest_cache
	@find . -type d -name "__pycache__" -prune -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✓ Reset completo terminado$(NC)"
	@echo "$(YELLOW)Siguiente paso sugerido: make setup$(NC)"

docker-up:
	@docker compose up -d || sg docker -c "docker compose up -d" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make setup-dockerized-sudo$(NC)" && exit 1)

docker-down:
	@docker compose down || sg docker -c "docker compose down" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make docker-down-sudo$(NC)" && exit 1)

docker-logs:
	@docker compose logs -f || sg docker -c "docker compose logs -f" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make docker-logs-sudo$(NC)" && exit 1)

docker-status:
	@docker compose ps || sg docker -c "docker compose ps" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make docker-status-sudo$(NC)" && exit 1)

docker-reset:
	@docker compose down -v || sg docker -c "docker compose down -v" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make docker-reset-sudo$(NC)" && exit 1)
	@docker compose up -d --build || sg docker -c "docker compose up -d --build" || (echo "$(YELLOW)⚠️  Error de permisos en Docker.$(NC)" && echo "$(YELLOW)   Opciones: (1) newgrp docker y reintentar, (2) make docker-reset-sudo$(NC)" && exit 1)

docker-up-sudo:
	@sudo docker compose up -d

docker-down-sudo:
	@sudo docker compose down

docker-status-sudo:
	@sudo docker compose ps

docker-logs-sudo:
	@sudo docker compose logs -f

docker-reset-sudo:
	@sudo docker compose down -v
	@sudo docker compose up -d --build

setup-docker:
	@echo "$(YELLOW)Agregando usuario al grupo docker...$(NC)"
	@sudo usermod -aG docker $$USER
	@echo "$(GREEN)✓ Completado.$(NC)"
	@echo "$(YELLOW)Opciones para aplicar cambios:$(NC)"
	@echo "  1) Cerrar sesión y volver a entrar (recomendado)"
	@echo "  2) Ejecutar ahora: newgrp docker"