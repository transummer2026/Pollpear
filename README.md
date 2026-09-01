_This project has been created as part of the 42 curriculum by blucken, hlichten, jrandet, pdemont, raphalme._

# Pollpear

Pollpear is a **real-time collaborative polling platform**. Users create rooms, run live
polls, chat, and see results update instantly across every connected browser. It is the
team's `ft_transcendence` project for the 42 curriculum, built as a full web application
with a frontend, a backend, a database, real-time features, an ML recommendation service,
and a hardened, fully containerized deployment.

---

## Table of Contents

- [Description](#description)
- [Instructions](#instructions)
  - [Prerequisites](#prerequisites)
  - [Step-by-step: from clone to a running app](#step-by-step-from-clone-to-a-running-app)
  - [The two `.env` files](#the-two-env-files)
  - [Accessing the application](#accessing-the-application)
  - [Useful commands](#useful-commands)
  - [Troubleshooting](#troubleshooting)
  - [Deployment (staging / production)](#deployment-staging--production)
- [Resources](#resources)
- [Team Information](#team-information)
- [Technical Stack](#technical-stack)
- [Database Schema](#database-schema)
- [Features List](#features-list)
- [Modules](#modules)
- [License](#license)

---

## Description

**Pollpear** is a web application for **collaborative, real-time polling and discussion**.
The core idea: bring people into shared _rooms_ where they create polls, vote, discuss in
a live chat, and watch every result and message propagate to all participants without a
page reload.

**Goal.** Deliver a complete, production-shaped web app that goes well beyond a static
CRUD: real-time collaboration, fine-grained authorization, a public REST API, machine-
learning recommendations, and a security- and observability-first deployment.

**Key features.**

- **Rooms** — public or private spaces with members, invitations, a live chat, and their
  own polls; owners and moderators manage them.
- **Polls** — several poll types (single choice, multiple choice, slider, free field),
  anonymous or attributed, vote-change control, hashtags, templates, and poll dependencies
  (a poll unlocked by a specific answer to a previous one).
- **Real-time everything** — votes, messages, presence, and notifications pushed live over
  WebSockets, with catch-up after a network drop.
- **Social graph** — friendships, blocking, reporting, user profiles with avatars/banners.
- **Personalized feed** — an ML service ranks and recommends polls per user.
- **Authentication** — email/password (Argon2-hashed) plus OAuth 2.0 (GitHub, 42, Google).
- **Advanced authorization** — role- and ownership-based permissions (user / moderator /
  admin) enforced with CASL.
- **Public API** — a key-authenticated REST API over the main resources.
- **Security & observability** — a WAF (ModSecurity/OWASP CRS), HashiCorp Vault for
  secrets, and Prometheus + Grafana monitoring.
- **Legal** — accessible Privacy Policy and Terms/legal pages.

The repository is a **superrepo** that orchestrates seven Git submodules
(`Pollpear_frontend`, `Pollpear_backend`, `Pollpear_gateway`, `Pollpear_ai`,
`Pollpear_cyber`, `Pollpear_infra`, `docs`) and the deployment tooling. The whole stack
runs with a **single command**.

---

## Instructions

This section takes a newcomer from an empty machine to a fully running Pollpear.

### Prerequisites

| Requirement                          | Details                                                                                                                                 |
| :----------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------- |
| **Git**                        | With submodule support (any recent version).                                                                                            |
| **make**                       | GNU Make.                                                                                                                               |
| **Docker Engine + Compose v2** | The`docker compose` (v2) subcommand is required. **Rootless Docker is supported and is what the evaluation machine uses.**      |
| **Disk space**                 | ≈ 18 GB free for images, build cache and repositories. A cold, full rebuild can take 20–30 min, so keep the build cache between runs. |
| **SSH access**                 | An SSH key authorized on the`transummer2026` GitHub organization, to clone the repo and its private submodules over SSH.              |
| **The two `.env` files**     | Not versioned — obtained from the team and placed as described[below](#the-two-env-files).                                              |

> **Ports & rootless Docker.** Under rootless Docker, unprivileged users cannot bind ports
> below 1024. On the evaluation machine the stack is therefore published on **8080 (HTTP)**
> and **8443 (HTTPS)**, and Redis on **6380** (a system `redis-server` already holds 6379).
> These values live in the root `.env`.

### Step-by-step: from clone to a running app

**1. Clone the superrepo with its submodules.**

```sh
git clone --recursive git@github.com:transummer2026/Pollpear.git
cd Pollpear
```

The submodules are pinned. `--recursive` is mandatory. After any `git pull`, refresh them:

```sh
git submodule update --init --recursive
```

> **Do not run `make sync`** on the evaluation checkout: it moves nested submodules to the
> branch head and can break the build. Use `git submodule update --init --recursive`
> instead.

**2. Put the two `.env` files in place** (see [the next section](#the-two-env-files)) and
set their permissions:

```sh
chmod 600 .env
chmod 644 Pollpear_cyber/.env   # MANDATORY — see note below
```

**3. Build and start the stack (single command).**

```sh
make up_prod
```

`make up_prod` builds all service images, applies the Prisma migrations, ensures TLS
certificates exist, then brings the stack up with `--wait` (it blocks until every
health-checked container is healthy). Expect **~2 min** with `SKIP_LETSENCRYPT=1`, longer
if a real Let's Encrypt attempt runs.

> The start command is **`make up_prod`**, _not_ `make prod` (which does not exist).

**4. Seed the database (mandatory, once, on an empty database).**

```sh
make seed_prod
```

`make seed_prod` creates the demo accounts and data. It **only works on an empty database**
and takes ~2–3 min (it includes a build). Run it **once**, and let `make up_prod` fully
finish first — never run the two concurrently.

**5. Open the app** at the HTTPS URL below.

The certificate is self-signed, so the browser shows a warning the first time — accept it.

### The two `.env` files

Both files are git-ignored, so a fresh clone does not contain them. Ask the team for them
and place them **exactly** here:

| File                      | Mounted where                                       | Contents (summary)                                                                                                                                                                               |
| :------------------------ | :-------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.env` (superrepo root) | Not mounted in any container                        | Host-structural config:`DOMAIN`, `ACME_EMAIL`, `VAULT_ADDR`, `VAULT_ROOT_TOKEN`, published ports (`NGINX_HTTP_PORT`, `NGINX_HTTPS_PORT`, `REDIS_HOST_PORT`), `SKIP_LETSENCRYPT`. |
| `Pollpear_cyber/.env`   | Mounted**read-only into the Vault container** | Application secrets: DB/Redis/Grafana passwords, the NestJS pepper, Garage tokens, htpasswd creds, and the OAuth client IDs/secrets + redirect URIs.                                             |

A commented template for the root file is provided as **`.env.example`**:

```sh
VAULT_ROOT_TOKEN="CHANGE_ME"
DOMAIN="dev.pollpear.com"
ACME_EMAIL="info@pollpear.com"
VAULT_ADDR="http://vault:8200"
NGINX_HTTP_PORT="80"
NGINX_HTTPS_PORT="443"
REDIS_HOST_PORT="6379"
SKIP_LETSENCRYPT="0"
```

For a **local evaluation run under rootless Docker**, the root `.env` typically uses:

```sh
NGINX_HTTP_PORT="8080"
NGINX_HTTPS_PORT="8443"
REDIS_HOST_PORT="6380"
SKIP_LETSENCRYPT="1"
```

> **File permissions matter.** The Vault container runs as a non-root UID (100) and reads
> `Pollpear_cyber/.env`. In mode `600` it **cannot read it and the stack fails to start**
> (symptom: `vault hook exited with status 1`, with no further explanation). Keep
> `Pollpear_cyber/.env` at **`644`**. The root `.env` is mounted nowhere — keep it `600`.
> If the root `.env` is missing, the error surfaces much later as
> `required variable DOMAIN is missing a value`.
>
> **OAuth redirect URIs must carry the published port.** When running on `:8443`, the
> redirect URIs in `Pollpear_cyber/.env` (and the ones declared at each provider) must be,
> e.g., `https://localhost:8443/api/auth/oauth/github/callback`. GitHub, 42 and Google are
> wired this way.

### Accessing the application

- **URL:** the app answers on `https://<DOMAIN>:<NGINX_HTTPS_PORT>/`. On the evaluation
  machine that is **[https://localhost:8443/](https://localhost:8443/)** (self-signed certificate → accept the
  browser warning).
- **Login field is the email**, not the username.
- **Demo accounts** (created by `make seed_prod`) share the password **`Password123!`** and
  use the email pattern `<username>@pollpear.com`.
  - **Verified, ready to log in:** `jojo0`, `apiuser`, `apimoderator`, `apiadmin`.
  - Other seeded accounts have an unverified email and return `403` on login.
- **Dataset after seeding:** ≈ 53 users, 20 rooms, 340 messages, 40 polls.

List other usable accounts straight from the database:

```sh
docker exec pollpear-postgres psql -U pollpear -d pollpear -tAc \
  "select email from users where is_email_verified limit 10;"
```

### Useful commands

All `make` targets (root `Makefile`):

| Command                                | Effect                                                                                                                                           |
| :------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------- |
| `make up_prod`                       | **Primary start.** Build, migrate, ensure certs, `up --wait` (prod/staging stack).                                                       |
| `make seed_prod`                     | Seed the prod/staging database —**once, on an empty DB**.                                                                                 |
| `make down_prod`                     | Stop the prod/staging stack.**Volumes are preserved** (the seeded DB survives).                                                            |
| `make up`                            | Dev stack (Pollpear services only), provisions Garage.                                                                                           |
| `make up_dev_full`                   | Dev stack**plus** the monitoring stack (Prometheus/Grafana/…).                                                                            |
| `make down` / `make down_dev_full` | Stop the dev / dev-full stack.                                                                                                                   |
| `make seed`                          | Seed the dev database (runs inside the backend container, via Vault).                                                                            |
| `make watch`                         | Dev stack with Compose`watch` (live rebuild on file changes).                                                                                  |
| `make deploy`                        | Full CD sequence (migrations + prod up + image prune).                                                                                           |
| `make re`                            | `fclean` then `up` (rebuild & restart the dev stack).                                                                                        |
| `make re_grafana`                    | Reset Grafana from scratch (container + data volume).                                                                                            |
| `make fclean`                        | Remove containers, networks,**volumes and images** of every stack. Destroys the seeded DB; a cold rebuild is 20–30 min. Use deliberately. |
| `make b_fclean`                      | Delete local branches whose remote is gone (repo + submodules).                                                                                  |
| `make sync`                          | Sync repo + submodules.**Avoid on the evaluation checkout** (see step 1).                                                                  |

**Inspecting the running stack** (container names are prefixed `pollpear-`):

```sh
# Container state, health and ports
docker ps --filter name=pollpear --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'
docker ps -a --format '{{.Names}}\t{{.Status}}' | grep -i exited      # what fell over
docker inspect pollpear-backend --format '{{.State.Health.Status}}'
docker inspect pollpear-backend --format '{{.RestartCount}}'          # crash loop?

# Logs
docker logs pollpear-backend --tail 80
docker logs pollpear-backend --since 10m
docker logs -f pollpear-backend                                       # follow live
docker logs pollpear-backend 2>&1 | grep -iE "error|exception|warn" | tail -30

# The Vault post_start hook logs go to a volume, not to `docker logs`:
cat "$(docker volume inspect pollpear-vault-logs --format '{{.Mountpoint}}')/seed.log"
```

**Querying the database:**

```sh
docker exec pollpear-postgres psql -U pollpear -d pollpear -c '\dt'   # list tables
docker exec pollpear-postgres psql -U pollpear -d pollpear -tAc "select count(*) from users;"
docker exec -it pollpear-postgres psql -U pollpear -d pollpear        # interactive session
```

**Smoke-testing the API** (expects `200`s):

```sh
curl -sk -o /dev/null -w '%{http_code}\n' https://localhost:8443/

J=$(mktemp)
curl -sk -c "$J" -X POST https://localhost:8443/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"jojo0@pollpear.com","password":"Password123!"}'
curl -sk -b "$J" https://localhost:8443/api/me
curl -sk -b "$J" https://localhost:8443/api/rooms
```

**Final health check** — expect **14 healthy containers** and HTTP **200**
(`certbot` and `redis-exporter` have no health check, which is normal):

```sh
docker ps --filter name=pollpear --format '{{.Names}}\t{{.Status}}'
curl -sk -o /dev/null -w '%{http_code}\n' https://localhost:8443/
```

### Troubleshooting

| Symptom                                                                       | Cause & fix                                                                                                                                                                                                                                                                          |
| :---------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vault hook exited with status 1` at startup                                | `Pollpear_cyber/.env` is unreadable by Vault (mode `600`). Fix: `chmod 644 Pollpear_cyber/.env && make up_prod`.                                                                                                                                                               |
| `required variable DOMAIN is missing a value`                               | The root`.env` is missing. Put it in place.                                                                                                                                                                                                                                        |
| `Conflict … "…_pollpear-vault" is already in use` / `No such container` | Two Compose operations ran at once (e.g.`seed_prod` before `up_prod` finished). Ensure nothing is running (`pgrep -af 'make (up\|down\|seed)\|docker compose'`), then `make up_prod`. **Do not run `make fclean`** for this — it deletes the seeded DB.                |
| Editing a`.env` value changes nothing                                       | Compose does not recreate an unchanged container; Vault still serves the old value. Recreate:`docker compose --env-file .env -f Pollpear_infra/compose.yml -f Pollpear_infra/compose.monitor.yml -f Pollpear_infra/compose.prod.yml up -d --force-recreate vault backend gateway`. |
| `500` on `GET /rooms`                                                     | A nested`Pollpear_shared` is off the commit its parent pins. Realign it: `git -C <parent>/Pollpear_shared checkout <sha the parent pins>`.                                                                                                                                       |
| OAuth callback never returns                                                  | The provider rejected the request upstream (redirect URI without the`:8443` port, or a client-secret mismatch). Read the provider's error.                                                                                                                                         |

---

### Deployment (staging / production)

At the **merge onto `staging`**, deployment runs automatically to **dev.pollpear.com** via
a self-hosted GitHub Actions runner. The workflow builds the services, applies the Prisma
migrations, regenerates the certificates, then restarts the stack with `--wait`
(validating health checks). Rollback = revert the merge on `staging` and push; the deploy
replays the previous state. Locally, `make deploy` runs the same CD sequence.

**First-deploy server checklist:** DNS `dev.pollpear.com` → server IP; the deploy `.env`
placed at `DEPLOY_ENV_FILE` (default `~/pollpear/.env`); `HTPASSWD_*` + `SMOKE_*` creds
present; the self-hosted runner (`self-hosted`, `staging`) online; the repo granted read
access to the infra's GHCR packages.

---

## Resources

**Classic references** (the official documentation for the technologies actually used):

- **Frontend** — [React](https://react.dev/), [Vite](https://vite.dev/),
  [TypeScript](https://www.typescriptlang.org/docs/),
  [Tailwind CSS](https://tailwindcss.com/docs), [shadcn/ui](https://ui.shadcn.com/),
  [Radix UI](https://www.radix-ui.com/), [React Router](https://reactrouter.com/),
  [React Hook Form](https://react-hook-form.com/), [Zod](https://zod.dev/),
  [SWR](https://swr.vercel.app/), [Socket.IO client](https://socket.io/docs/v4/).
- **Backend** — [NestJS](https://docs.nestjs.com/), [Prisma](https://www.prisma.io/docs),
  [CASL](https://casl.js.org/), [Passport](https://www.passportjs.org/),
  [Argon2](https://github.com/ranisalt/node-argon2), [Socket.IO](https://socket.io/docs/v4/),
  [OAuth 2.0](https://oauth.net/2/).
- **Gateway** — [Rust](https://doc.rust-lang.org/book/),
  [axum](https://docs.rs/axum/latest/axum/), [tokio](https://tokio.rs/),
  [tower-http](https://docs.rs/tower-http/).
- **AI service** — [FastAPI](https://fastapi.tiangolo.com/),
  [scikit-learn](https://scikit-learn.org/stable/documentation.html),
  [pandas](https://pandas.pydata.org/docs/), [NumPy](https://numpy.org/doc/).
- **Data & infra** — [PostgreSQL](https://www.postgresql.org/docs/),
  [Redis](https://redis.io/docs/), [Docker](https://docs.docker.com/),
  [HashiCorp Vault](https://developer.hashicorp.com/vault/docs),
  [nginx](https://nginx.org/en/docs/),
  [ModSecurity](https://github.com/owasp-modsecurity/ModSecurity) +
  [OWASP CRS](https://coreruleset.org/),
  [Garage S3](https://garagehq.deuxfleurs.fr/documentation/),
  [Prometheus](https://prometheus.io/docs/) & [Grafana](https://grafana.com/docs/).

**Use of AI.**

An AI coding assistant (Claude) was used as a support tool during development. Concretely,
it was used to:

- **assist development** — pairing on implementation, debugging and refactoring across the
  sub-repositories;
- **run and review a full test campaign** — reproducing behaviours against the running stack,
  cross-checking findings and verifying proposed fixes before they were applied;
- **write this README** — drafting and structuring the document from the codebase, the module
  plan and the test campaign results.

All AI output was reviewed by the team before being kept; design decisions and the final
content remain the team's own.

---

## Team Information

Roles are based on the team's project-management minutes.

| 42 login     | Member (GitHub)                    | Nickname | Role (per 2026-08-20 minutes)  |
| :----------- | :--------------------------------- | :------- | :----------------------------- |
| `blucken`  | `blucken`                        | Ben      | **Tech Lead**            |
| `hlichten` | `Hyliah`                         | Hygie    | **Product Owner (PO)**   |
| `jrandet`  | `jrandetdev` (Joséphine Randet) | Jo       | **Project Manager (PM)** |
| `pdemont`  | `pieric-ux` (Pieric Demont)      | Pieric   | **Developer**            |
| `raphalme` | `RaphyStoll` (Raphaël Ferreira) | Raph     | **Developer**            |

---

## Technical Stack

Pollpear is a **polyglot microservice** architecture: an nginx edge (with a WAF) fronts a
React SPA, a Rust API gateway, a NestJS backend, and a Python ML service, backed by
PostgreSQL, Redis, Garage object storage and HashiCorp Vault, with Prometheus/Grafana for
observability.

### Frontend — `Pollpear_frontend`

- **React 19** + **TypeScript**, bundled with **Vite**.
- **Tailwind CSS 4** for styling, **shadcn/ui** on top of **Radix UI** / **Base UI**
  primitives; icons via lucide/hugeicons; charts via **Recharts**.
- **React Router** for routing, **React Hook Form + Zod** for validated forms,
  **SWR** for data fetching/caching, **Socket.IO client** for real-time updates,
  **next-themes** for light/dark theming, **sonner** for toasts.
- Built to a static bundle and served by nginx (`front-dist`).

### Backend — `Pollpear_backend`

- **NestJS 11** on **Node ≥ 25**, **TypeScript**.
- **Prisma 7** ORM over PostgreSQL (`@prisma/adapter-pg`); Zod schemas are **generated from
  the Prisma schema** into `Pollpear_shared` (`prisma-zod-generator`) and shared across
  services.
- **CASL** (`@casl/ability`, `@casl/prisma`) for authorization.
- **Passport** strategies: local, JWT, and OAuth 2.0 (GitHub, Google, 42); **Argon2** for
  password hashing.
- **Socket.IO** WebSocket gateway for real-time; **ioredis** for Redis (presence,
  pub/sub, rate-limit state).
- **Nodemailer** (`@nestjs-modules/mailer`) + Handlebars for transactional email;
  **Multer + sharp** for image uploads; **@aws-sdk/client-s3** to store them in **Garage**.
- **Swagger / Scalar** API reference; `@nestjs/schedule` for cron tasks.
- Modules span `auth`, `users`, `me`, `rooms`, `messages`, `polls`, `options`, `votes`,
  `invitation`, `friendship`, `block`, `report`, `ban`, `notification`, `presence`,
  `feed`, `search`, `hashtags`, `api` (public API), `api-key`, `admin`, `casl`, `vault`,
  `secrets`, `storage`, `file-upload`, `mail`, `health`, `revocation`, `websocket`.

### Gateway — `Pollpear_gateway` (Rust)

- **Rust (edition 2024)** with **axum 0.8** (+ `ws`), **hyper** / **tower** / **tower-http**.
- Acts as the **edge for `/api`**: session validation, **API-key authentication**
  (SHA-256 hashing), **rate limiting**, CORS, path stripping, and **WebSocket proxying**
  (`tokio-tungstenite`).
- Reads its secrets from **Vault** (`vaultrs`) and state from **Redis**.

### AI service — `Pollpear_ai` (Python)

- **Python 3.14**, **FastAPI** + **uvicorn**.
- **scikit-learn**, **NumPy**, **pandas**, **joblib**, **matplotlib** for the recommendation
  model; **psycopg** + **SQLAlchemy** to read data; **httpx** as HTTP client.
- Structured into `data` (loading), `training` (trainer), `models`/`scoring` (feed model &
  recommender), and `evaluation`; `prometheus-fastapi-instrumentator` exposes metrics.

### Infrastructure — `Pollpear_infra` & `Pollpear_cyber`

- **Docker Compose** orchestration split across `compose.yml`, `compose.dev.yml`,
  `compose.prod.yml`, `compose.monitor.yml`.
- **nginx** edge with **ModSecurity (OWASP CRS)** WAF, TLS via **Certbot** / Let's Encrypt.
- **HashiCorp Vault** for secret management (AppRole per service).
- **PostgreSQL**, **Redis**, **Garage** (S3-compatible object storage).
- **Prometheus + Grafana + Alertmanager** with node, cAdvisor, postgres and redis
  exporters.
- `Pollpear_cyber` holds the application secrets and the Vault migration tooling.

### Why these choices

- **PostgreSQL** — a relational schema with strong, well-defined relations, transactions,
  enums and DB-level CHECK constraints (e.g. the friendship-pair invariants) fits the
  domain far better than a document store; Prisma gives type-safe access and migrations.
- **NestJS** — an opinionated, modular framework (DI, guards, pipes) that keeps a large
  domain (30+ modules) organized and testable, with first-class WebSocket and validation
  support.
- **A Rust gateway** — a fast, memory-safe edge to concentrate cross-cutting concerns
  (auth, rate limiting, API-key handling, WS proxying) in front of the backend.
- **A separate Python ML service** — keeps the recommendation model in the ecosystem
  (scikit-learn/pandas) best suited to it, decoupled from the request path.
- **Vault + WAF** — secrets are never baked into images, and a WAF hardens the public
  surface — both mandated by the security-oriented module.
- **Shared Zod schemas generated from Prisma** — one source of truth for validation across
  backend, gateway and frontend.

---

## Database Schema

**Engine:** PostgreSQL, modelled with Prisma (`Pollpear_backend/prisma/schema.prisma`).
Integer autoincrement primary keys, `snake_case` table/column mapping, `created_at` /
`updated_at` timestamps throughout, and **soft-deletes** (`deleted_at` / status enums) on
most user-facing entities.

### Core tables

| Table                                        | Purpose                  | Key fields & relations                                                                                                                                                                                                                                                                          |
| :------------------------------------------- | :----------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **users**                              | Accounts & profiles      | `username` (unique), `email` (unique), `password_hash`, `role` (`user`/`moderator`/`admin`), `gender`, `birthdate`, `nationality`, profile fields, `is_online`, `is_email_verified`, `visibility`, `avatar_url`, `banner_url`, `user_theme`. Hub of the schema. |
| **oauths**                             | Linked OAuth identities  | `provider` (`google`/`42`/`github`), `provider_user_id`, tokens, `grant_type`; unique `(provider, provider_user_id)`; FK → `users`.                                                                                                                                            |
| **rooms**                              | Collaborative spaces     | `name`, `description`, `visibility` (public/private), `status`, `ends_at`; FK `created_by` → `users`.                                                                                                                                                                            |
| **room_members**                       | Room membership          | unique`(room_id, user_id)`, `joined_at`; FKs → `rooms`, `users`.                                                                                                                                                                                                                       |
| **invitations**                        | Room invites             | `status` (pending/accepted/rejected); unique `(invitee_id, room_id)`; FKs → `rooms` + inviter/invitee `users`.                                                                                                                                                                         |
| **messages**                           | Room chat                | `content`, FKs `author_id` → `users`, `room_id` → `rooms`.                                                                                                                                                                                                                          |
| **polls**                              | Polls                    | `type` (single/multiple/slider/free_field), `visibility`, `status` (pending/active/closed), `allow_change_vote`, `is_anonymous`, `published_at`, `ends_at`; FKs `created_by` → `users`, optional `room_id` → `rooms` (SetNull).                                         |
| **options**                            | Poll options             | `text`, slider labels, `order`; FK → `polls`.                                                                                                                                                                                                                                            |
| **votes**                              | A user's vote on a poll  | unique`(created_by, poll_id)`, optional `free_field`; FKs → `users`, `polls`.                                                                                                                                                                                                          |
| **vote_options**                       | Options chosen by a vote | composite PK`(vote_id, option_id)`.                                                                                                                                                                                                                                                           |
| **poll_dependencies**                  | Conditional polls        | composite PK`(child_poll_id, option_id)` — a poll gated by a specific option.                                                                                                                                                                                                                |
| **hashtags** / **poll_hashtags** | Tagging                  | `hashtags.name` unique; `poll_hashtags` join `(poll_id, hashtag_id)`.                                                                                                                                                                                                                     |
| **poll_templates**                     | Saved poll templates     | join`(user_id, poll_id)`.                                                                                                                                                                                                                                                                     |
| **friendships**                        | Social graph             | `status` (pending/accepted/rejected), ordered pair `(user_a_id, user_b_id)` + `addressee_id`; enforced by two **DB CHECK constraints** (`user_a_id < user_b_id`; addressee in the pair).                                                                                          |
| **blocks**                             | User blocking            | unique`(blocker_id, blocked_id)`.                                                                                                                                                                                                                                                             |
| **reports**                            | Moderation reports       | `reason` enum, `content`, and optional FKs to the reported room/message/poll/option/hashtag.                                                                                                                                                                                                |
| **bans** / **ban_attachments**   | Bans                     | reason, window (`started_at`/`ended_at`), `banned_by` / `unbanned_by`; optional attachments.                                                                                                                                                                                            |
| **notifications**                      | User notifications       | `type` (friend_request, friend_accepted, poll_update, room_invitation, room_invitation_accepted, room_message, other), `is_read`, optional `actor_id`.                                                                                                                                    |
| **api_keys**                           | Public-API credentials   | `key_hash` (unique), `app_name`, `revoked`, `expired_at`; FK `owner_id` → `users` — the identity the API key acts as.                                                                                                                                                             |

**Relationship highlights.** `users` is the central hub (one-to-many to rooms, polls, votes,
messages, notifications, API keys; many-to-many to rooms via `room_members`, to other users
via `friendships`/`blocks`). `rooms` own messages, invitations, members and (optionally)
polls. `polls` own options and votes, with `poll_dependencies` allowing a poll to depend on
a specific option of another. Enums encode roles, visibility, statuses and types at the DB
level.

---

## Features List

| Feature                                | Description                                                                                                                                                         |
| :------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Sign-up / Login**              | Email + password with**Argon2** hashing; email verification; validated on front and back (Zod / class-validator).                                             |
| **OAuth 2.0 login**              | Sign in with**GitHub**, **42** and **Google**; deferred onboarding for OAuth sign-ups (profile completion).                                       |
| **User profiles**                | Editable profile, avatar & banner uploads (stored in Garage S3), theme, visibility, bio.                                                                            |
| **Rooms**                        | Create/join public or private rooms, membership, invitations, room lifecycle (status/expiry).                                                                       |
| **Live chat**                    | Real-time room messaging over WebSockets, with catch-up after disconnection.                                                                                        |
| **Polls & voting**               | 4 poll types (single/multiple/slider/free field), anonymous or attributed, vote-change control, hashtags, templates, poll dependencies.                             |
| **Real-time updates**            | Live propagation of votes, messages, presence and notifications to all connected clients.                                                                           |
| **Presence**                     | Online/last-seen status, multi-tab presence.                                                                                                                        |
| **Notifications**                | Complete in-app notification system (friend requests/accepted, poll updates, room invitations & messages).                                                          |
| **Social graph**                 | Friendships, blocking, reporting users/content.                                                                                                                     |
| **Personalized feed**            | ML-ranked recommendation feed of polls, with graceful degradation when the AI service is down.                                                                      |
| **Advanced search**              | Search across the platform's resources.                                                                                                                             |
| **Public REST API**              | Key-authenticated API over 5 resources (`/me`, `/users`, `/rooms`, `/polls`, `/hashtags`) with pagination and soft-deletes; tenant isolation per API key. |
| **Roles & permissions**          | user / moderator / admin, ownership- and role-based authorization via CASL.                                                                                         |
| **Moderation**                   | Reports, bans (with attachments), moderator/admin capabilities.                                                                                                     |
| **Legal pages**                  | Accessible Privacy Policy and Terms/legal pages.                                                                                                                    |
| **Responsive, multi-browser UI** | Verified identical rendering on Chromium, Firefox and WebKit; no horizontal overflow at 393 px.                                                                     |
| **Security hardening**           | WAF (ModSecurity/OWASP CRS), Vault-managed secrets, per-service AppRole.                                                                                            |
| **Observability**                | Prometheus metrics + Grafana dashboards + Alertmanager.                                                                                                             |

---

## Modules

Point rule: **Major = 2 pts, Minor = 1 pt.** The modules Pollpear delivers, per the team's
module plan (`docs/Conception/Recapitulatif-modules.md`):

| Module | Category | Type | Pts | How it is built |
| :--- | :--- | :--- | :-: | :--- |
| Frontend framework | Web | Minor | 1 | React 19 + Vite + Tailwind/shadcn. |
| Backend framework | Web | Minor | 1 | NestJS 11 (modular, DI, guards). |
| Real-time feature | Web | Major | 2 | Socket.IO gateway + Redis; live votes/chat/presence; catch-up after a network drop. |
| Complete notification system | Web | Minor | 1 | `Notification` model + real-time delivery (7 types). |
| Use an ORM | Web | Minor | 1 | Prisma 7 over PostgreSQL, generated Zod schemas. |
| User-to-user interaction | Web | Major | 2 | Rooms, live chat, friendships and blocking between users. |
| Public API to the database | Web | Major | 2 | Key-authenticated REST API over 5 resources, with per-key isolation. |
| Custom design system | Web | Minor | 1 | Bespoke theming and design system on shadcn/Radix. |
| Advanced search | Web | Minor | 1 | Backend `search` module + `SearchPage`. |
| Multi-browser support | Accessibility/i18n | Minor | 1 | Identical rendering on Chromium, Firefox and WebKit. |
| Standard user management & auth | User mgmt | Major | 2 | Email/password (Argon2), email verification, sessions. |
| OAuth 2.0 | User mgmt | Minor | 1 | GitHub / 42 / Google via Passport. |
| ML recommendation | AI | Major | 2 | Python/scikit-learn service ranking a personalized feed. |
| WAF/ModSecurity + Vault | Cybersecurity | Major | 2 | nginx + ModSecurity/OWASP CRS, and HashiCorp Vault for every secret. |
| Prometheus + Grafana monitoring | DevOps | Major | 2 | Full monitoring stack with node, cAdvisor, postgres and redis exporters. |
| Microservices backend | DevOps | Major | 2 | Polyglot services: React SPA, Rust gateway, NestJS backend, Python AI. |
| Health checks, status & backups | DevOps | Minor | 1 | Container health checks and backup tooling. |
| Custom module (Major) — API gateway | Modules of choice | Major | 2 | Rust/axum edge gateway: session auth, API keys, rate limiting, WebSocket proxy. |
| Custom module (Minor) — object storage | Modules of choice | Minor | 1 | Garage S3-compatible storage for media (avatars, banners). |

**Point total: 28 pts** — 9 Majors × 2 + 10 Minors × 1.

---

## License

UNLICENSED — academic project for the 42 curriculum. All rights reserved by the authors.
