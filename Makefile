up:
	docker compose -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml up -d

down:
	docker compose -f ./Pollpear_infra/compose.yml -f ./Pollpear_infra/compose.dev.yml down

up_prod:
	docker compose -f ./Pollpear_infra/compose.yml --profile prod up -d

down_prod:
	docker compose -f ./Pollpear_infra/compose.yml --profile prod down
