up:
	docker compose -f ./Pollpear_infra/compose.dev.yml up -d

down:
	docker compose -f ./Pollpear_infra/compose.dev.yml down

up_prod:
	docker compose -f ./Pollpear_infra/compose.prod.yml up -d

down_prod:
	docker compose -f ./Pollpear_infra/compose.prod.yml down
