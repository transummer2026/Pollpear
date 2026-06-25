ENV_FILE := $(wildcard .env)
COMPOSE_FLAGS := $(if $(ENV_FILE),--env-file .env,)

sync:
	@echo "→ Sync repo principal..."
	@git fetch --all
	@git stash --include-untracked --quiet || true
	@git pull --rebase
	@git stash pop --quiet 2>/dev/null || true
	@echo "→ Sync submodules (checkout branche trackée, pas HEAD détaché)..."
	@git submodule foreach 'branch=$$(git config -f "$$toplevel/.gitmodules" "submodule.$$name.branch" 2>/dev/null || echo dev); echo "  $$name → $$branch"; git fetch origin; git checkout "$$branch"; git pull --rebase origin "$$branch"'
	@echo "✓ Tout est synced"

up:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml up -d

down:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml down

up_prod:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml --profile prod up -d

down_prod:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml --profile prod down
