sync:
	@echo "→ Fetch repo principal..."
	@git fetch --all
	@echo "→ Sync submodules (checkout branche trackée, pas HEAD détaché)..."
	@git submodule foreach 'branch=$$(git config -f "$$toplevel/.gitmodules" "submodule.$$name.branch" 2>/dev/null || echo dev); echo "  $$name → $$branch"; git fetch origin; git checkout "$$branch"; git pull --rebase origin "$$branch"'
	@echo "✓ Tout est synced"

up:
	docker compose -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml up -d

down:
	docker compose -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml down

up_prod:
	docker compose -f ./Pollpear_infra/compose.yml --profile prod up -d

down_prod:
	docker compose -f ./Pollpear_infra/compose.yml --profile prod down
