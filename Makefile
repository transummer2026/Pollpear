ENV_FILE := $(wildcard .env)
COMPOSE_FLAGS := $(if $(ENV_FILE),--env-file .env,)

all:
	@echo "→ Makefile commands:"
	@echo "  - sync: Sync the repository and submodules"
	@echo "  - up: Start the development containers"
	@echo "  - down: Stop the development containers"
	@echo "  - up_prod: Start the production containers"
	@echo "  - down_prod: Stop the production containers"
	@echo "  - fclean: Remove all containers, networks, and volumes"
	@echo "  - re: Rebuild and restart the development containers"
	@echo "  - re_grafana: Reset Grafana from scratch (container + data volume)"

sync:
	@echo "→ Sync repo principal..."
	@git fetch --all
	@git stash --include-untracked --quiet || true
	@git pull --rebase
	@git stash pop --quiet 2>/dev/null || true
	@echo "→ Sync submodules (checkout branche trackée, pas HEAD détaché)..."
	@git submodule foreach --recursive 'branch=$$(git config -f "$$toplevel/.gitmodules" "submodule.$$name.branch" 2>/dev/null || echo dev); echo "  $$name → $$branch"; git fetch origin; git checkout "$$branch"; git pull --rebase origin "$$branch"'
	@echo "✓ Tout est synced"

up:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml up -d

down:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml down

watch:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml watch

fclean:
	-docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml down --rmi all -v --remove-orphans --timeout 15
	-docker rm -f $$(docker ps -aq --filter "name=pollpear") 2>/dev/null || true

re: fclean up

re_grafana:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml rm -sf grafana
	-docker volume rm pollpear_infra_grafana-data
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml up -d grafana
