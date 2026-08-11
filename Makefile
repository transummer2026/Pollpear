ENV_FILE := $(wildcard .env)
COMPOSE_FLAGS := $(if $(ENV_FILE),--env-file .env,)

GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
CYAN   := \033[0;36m
RESET  := \033[0m

GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
CYAN   := \033[0;36m
RESET  := \033[0m

all:
	@echo "→ Makefile commands:"
	@echo "  - sync: Sync the repository and submodules"
	@echo "  - up: Start the development containers (provisions Garage)"
	@echo "  - down: Stop the development containers"
	@echo "  - seed: Seed the database (runs inside the backend container, via Vault)"
	@echo "  - up_prod: Start the production containers"
	@echo "  - down_prod: Stop the production containers"
	@echo "  - deploy: Run the full CD sequence (migrations + up prod + image prune)"
	@echo "  - fclean: Remove containers, networks, volumes and images of every stack (dev light, dev full, prod/staging)"
	@echo "  - fclean: Remove containers, networks, volumes and images of every stack (dev light, dev full, prod/staging)"
	@echo "  - re: Rebuild and restart the development containers"
	@echo "  - re_grafana: Reset Grafana from scratch (container + data volume)"
	@echo "  - b_fclean: Delete local branches whose remote branch is gone (repo + submodules)"

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
	@bash ./Pollpear_infra/scripts/garage-init.sh

down:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml down
	docker volume rm pollpear-vault-approle

up_dev_full:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.monitor.yml -f ./Pollpear_infra/compose.dev.yml -f ./Pollpear_infra/compose.monitor.dev.yml up -d
	@bash ./Pollpear_infra/scripts/garage-init.sh
down_dev_full:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.monitor.yml -f ./Pollpear_infra/compose.dev.yml -f ./Pollpear_infra/compose.monitor.dev.yml down

up_prod:
	@bash ./Pollpear_infra/scripts/ensure-certs.sh
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.monitor.yml -f ./Pollpear_infra/compose.prod.yml up -d --build --wait
	@bash ./Pollpear_infra/scripts/garage-init.sh
down_prod:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.monitor.yml -f ./Pollpear_infra/compose.prod.yml down

deploy:
	@bash ./Pollpear_infra/scripts/deploy.sh

watch: up
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml watch

seed: up
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml run --rm backend npm run seed

fclean:
	@bash ./Pollpear_infra/scripts/fclean.sh

re: fclean up

re_grafana:
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.monitor.yml -f ./Pollpear_infra/compose.dev.yml -f ./Pollpear_infra/compose.monitor.dev.yml rm -sf grafana
	-docker volume rm pollpear-grafana-data
	docker compose $(COMPOSE_FLAGS) -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.monitor.yml -f ./Pollpear_infra/compose.dev.yml -f ./Pollpear_infra/compose.monitor.dev.yml up -d grafana

b_fclean:
	@for repo in . $$(git config --file .gitmodules --get-regexp path | awk '{print $$2}'); do \
		printf "$(CYAN)→ %s$(RESET)\n" "$$repo"; \
		( cd "$$repo"; \
		  git fetch --prune --quiet; \
		  current=$$(git branch --show-current); \
		  gone=$$(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | awk '$$2 == "[gone]" {print $$1}'); \
		  if [ -z "$$gone" ]; then \
			printf "  $(GREEN)✓ rien à nettoyer$(RESET)\n"; \
		  else \
			for branch in $$gone; do \
				if [ "$$branch" = "$$current" ]; then \
					printf "  $(YELLOW)! %s ignorée (branche courante)$(RESET)\n" "$$branch"; \
				else \
					git branch -D "$$branch" >/dev/null; \
					printf "  $(RED)✗ %s supprimée$(RESET)\n" "$$branch"; \
				fi; \
			done; \
		  fi ); \
	done
