# `app-socios-estadio` — root

SaaS platform for member registration of a sports club with facial verification and a points system. Members register via web with liveness check (anti-spoof), identify themselves at the stadium by face (facial search on access), and accumulate points redeemable for benefits.

> **For agents / LLMs / humans new to the project**: read this README first, then [`app-socios-estadio-docs/AGENTS.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/AGENTS.md) (operational rules), then the doc of your subsystem (see "Documentation map" in the docs repo).

---

## This repo (root)

The root contains **only** the shared Terraform infrastructure and the minimum entry points (`AGENTS.md` at the root + this `README.md` + `docs/`). All application code and detailed documentation (SPEC, ARCHITECTURE, INFRASTRUCTURE, CHECKLIST, ENVIRONMENT, HARNESS, Makefile) live in separate repos.

## Project repo map

| Repo | Contents |
|---|---|
| [`arnigon-holdings/app-socios-estadio-infra`](https://github.com/arnigon-holdings/app-socios-estadio-infra) | **This repo**: root + `infrastructure/` (Terraform) + `docs/` + root `AGENTS.md` |
| [`arnigon-holdings/app-socios-estadio-docs`](https://github.com/arnigon-holdings/app-socios-estadio-docs) | Documentation: AGENTS, ARCHITECTURE, SPEC, INFRASTRUCTURE, CHECKLIST, ENVIRONMENT, HARNESS, Makefile |
| [`arnigon-holdings/app-socios-estadio-backend`](https://github.com/arnigon-holdings/app-socios-estadio-backend) | Rails 8 API (polyrepo, own .git) |
| [`arnigon-holdings/app-socios-estadio-frontend`](https://github.com/arnigon-holdings/app-socios-estadio-frontend) | React SPA — members (polyrepo, own .git) |
| [`arnigon-holdings/app-socios-estadio-admin`](https://github.com/arnigon-holdings/app-socios-estadio-admin) | React SPA — admin (polyrepo, own .git) |
| [`arnigon-holdings/app-socios-estadio-face-search`](https://github.com/arnigon-holdings/app-socios-estadio-face-search) | Go facial search service (polyrepo, own .git) |

> **Polyrepo convention**: each subsystem is an independent git repo. The root only has shared infra + entry points. See [`app-socios-estadio-docs/`](https://github.com/arnigon-holdings/app-socios-estadio-docs) for the full documentation.

## Stack

| Layer | Technology | Repo |
|---|---|---|
| User frontend (SPA) | React 19 + Vite + Tailwind v4 + shadcn/ui | `app-socios-estadio-frontend` |
| Admin panel (SPA) | React 19 + Vite + Tailwind v4 + shadcn/ui + TanStack Query | `app-socios-estadio-admin` |
| Backend API | Ruby on Rails 8 API-only + PostgreSQL + Redis | `app-socios-estadio-backend` |
| Face liveness (web) | AWS Lambda + API Gateway + Cognito | `infrastructure/frontend-liveness/` (this repo) |
| Face indexing (S3 + Rekognition) | Rails (`S3Uploader` + `FaceIndexer`) | `app-socios-estadio-backend` |
| Face search (search + presigned) | Go 1.24 + AWS SDK v2 | `app-socios-estadio-face-search` |
| Infrastructure as code (backend AWS) | Terraform (S3 + Rekognition + IAM) | `infrastructure/aws/` (this repo) |
| Infrastructure as code (frontend AWS) | Terraform (API Gateway + Lambda + Cognito + IAM + Lightsail) | `infrastructure/frontend-liveness/` (this repo) |
| Prod DB | GCP Cloud SQL (PostgreSQL) | Terraform (future) |
| Prod host | GCP Cloud Run | Dockerfiles already ready |

## Root structure

```
.
├── README.md                  ← this file (entry point)
├── AGENTS.md                  ← root operational rules (summary; full version in docs repo)
├── docs/
│   └── ARQUITECTURA.md        ← architecture overview (mirror of docs repo ARCHITECTURE.md)
│
└── infrastructure/            ← shared Terraform (tracked in this repo)
    ├── aws/                   ← backend AWS (S3 + Rekognition + IAM)
    │   ├── main.tf
    │   └── modules/{s3,rekognition}/
    └── frontend-liveness/     ← frontend AWS (API Gateway + Lambda + Cognito + IAM + Lightsail)
        ├── main.tf
        ├── README.md          ← what it deploys + outputs consumed by the frontend
        └── modules/{apigateway,lambda,cognito,iam,lightsail}/
```

> The 4 app directories (`backend/`, `frontend/`, `admin/`, `face-search-service/`) **do not live in this repo**. They are independent polyrepos with their own `.git`. If you see them locally, they are clones/worktrees that keep their own history.

---

## Quickstart (entire stack, local dev)

Prerequisites: Docker, Node 20+, Ruby 3.4 (or use Docker), AWS CLI configured with dev account credentials.

```bash
# 1. Clone each repo (polyrepo)
git clone https://github.com/arnigon-holdings/app-socios-estadio-infra.git
git clone https://github.com/arnigon-holdings/app-socios-estadio-backend.git backend
git clone https://github.com/arnigon-holdings/app-socios-estadio-frontend.git frontend
git clone https://github.com/arnigon-holdings/app-socios-estadio-admin.git admin
git clone https://github.com/arnigon-holdings/app-socios-estadio-face-search.git face-search-service
git clone https://github.com/arnigon-holdings/app-socios-estadio-docs.git  # optional, for AGENTS.md

# 2. Backend: dependencies + DB
cd backend
docker compose up -d postgres redis
docker compose run --rm app bundle install
docker compose run --rm app bundle exec rails db:migrate db:seed
cd ..

# 3. Backend: AWS credentials in .env (gitignored)
cp backend/.env.example backend/.env.aws
# edit backend/.env.aws with real AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY

# 4. Start the full backend (includes face-search Go)
cd backend && docker compose up -d && cd ..

# 5. Frontends (one terminal each)
cd frontend && npm install && npm run dev    # http://localhost:5173
cd admin && npm install && npm run dev        # http://localhost:5174

# 6. Smoke test
curl -s http://localhost:3000/up            # rails health
curl -s http://localhost:8081/health        # go health
```

**Default admin login** (seed, configurable via `SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD` in `backend/.env.development`): defaults to `admin@appperfil.cl` / `Admin123!`.

---

## Documentation

### In this repo

| File | Purpose |
|---|---|
| [`README.md`](./README.md) | This file — project entry point, stack, quickstart, conventions |
| [`AGENTS.md`](./AGENTS.md) | Operational rules for agents (short version; full version in docs repo) |
| [`docs/ARQUITECTURA.md`](./docs/ARQUITECTURA.md) | Architecture diagrams and main flows (user registration, face search) |
| [`infrastructure/README.md`](./infrastructure/README.md) | Terraform infrastructure overview (backend AWS + frontend liveness) |
| [`infrastructure/frontend-liveness/README.md`](./infrastructure/frontend-liveness/README.md) | Face Liveness Terraform module — what it deploys and outputs consumed by the frontend |

### External (docs repo)

All detailed documentation (SPEC, ARCHITECTURE, INFRASTRUCTURE, CHECKLIST, ENVIRONMENT, HARNESS, Makefile) lives in:

👉 **[`arnigon-holdings/app-socios-estadio-docs`](https://github.com/arnigon-holdings/app-socios-estadio-docs)**

There you will find:
- Full operational rules for agents ([AGENTS.md](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/AGENTS.md))
- Functional source of truth ([SPEC.md](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/SPEC.md))
- Architecture decisions ([ARCHITECTURE.md](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/ARCHITECTURE.md))
- Terraform overview ([INFRASTRUCTURE.md](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/INFRASTRUCTURE.md))
- Project status ([CHECKLIST.md](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/CHECKLIST.md))
- Environment variables ([ENVIRONMENT.md](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/ENVIRONMENT.md))
- Work framework ([HARNESS.md](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/HARNESS.md))
- Common commands (Makefile)

---

## Project conventions

### UX Rule: hide the technology layer

No user-facing text (member, admin, or any role) may mention providers or infrastructure services: AWS, GCP, Azure, Rekognition, S3, Cloud SQL, Lambda, Cloud Run, etc. User-facing messages describe behavior, not brand:

- ❌ `"Searching matches in Rekognition…"`
- ✅ `"Searching matches…"`
- ❌ `"Connecting with AWS services..."`
- ✅ `"Connecting with the verification service..."`

Allowed exception: internal API contract field names (`rekognition_face_id`, `s3_key`) may exist in types/JSON, but are not shown to the user.

### Agent communication

- **Chat with humans**: concise, direct, no fluff. "Caveman" style per owner preference.
- **Code, names, comments, tests, commits, PRs**: normal, readable, maintainable.
- **No emojis** unless the user explicitly requests them.
- **No obvious comments** in code — code must be self-explanatory; if it needs a comment, refactor.

### Security

- **Never hardcode credentials**. Every credential lives in a gitignored `.env*` or in a secret manager (production).
- **Do not commit `.env`, `.env.local`, `.env.aws`, `.env.production`, etc.** — `.gitignore` already covers them.
- **Verify before committing**: `git grep -E "AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}"` should return empty.
- **Validate inputs at entry boundaries** (controllers, Go handlers, form schemas).
- **Least privilege in AWS IAM** — `infrastructure/aws/main.tf` defines a policy with `aws:ResourceAccount` condition.

### Operational risk

- **Read-only**: the agent operates without confirmation.
- **Draft**: changes with simulated external side effects (Terraform plan, dry-run).
- **External write**: AWS / DB / external APIs — requires explicit human approval (`terraform apply`, `docker compose down -v`, git push, etc).

---

## Quick command reference

```bash
# Backend
cd backend
docker compose up -d
docker compose logs -f app
docker compose run --rm app bundle exec rails db:migrate db:seed

# Frontend
cd frontend && npm run dev   # http://localhost:5173
cd admin && npm run dev      # http://localhost:5174

# Terraform
cd infrastructure/aws && terraform init && terraform plan
cd infrastructure/frontend-liveness && terraform init && terraform plan
```

---

## Current status

See [`app-socios-estadio-docs/CHECKLIST.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/CHECKLIST.md). TL;DR:

- **M0-M5 ✅**: setup, public registration, admin, security, facial search.
- **High priority pending**: rotate AWS credentials leaked in git history (see CHECKLIST).
- **Medium priority pending**: unit tests (`FaceIndexer`, `S3Uploader`, Go service), retry/backoff, remote Terraform state.
- **Phase 2**: Twilio WhatsApp, referrals, transactional email.

---

## For LLMs starting on the project

1. **Read this README** (general orientation).
2. **Read [`app-socios-estadio-docs/AGENTS.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/AGENTS.md)** (operational rules — non-negotiable).
3. **Read [`app-socios-estadio-docs/SPEC.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/SPEC.md)** (what the product does).
4. **Read [`app-socios-estadio-docs/ARCHITECTURE.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/ARCHITECTURE.md)** (boundaries — what your subsystem may touch).
5. **If you'll touch frontend**: also read [`app-socios-estadio-frontend/CLAUDE.md`](https://github.com/arnigon-holdings/app-socios-estadio-frontend/blob/main/CLAUDE.md).
6. **If you'll touch admin**: also read [`app-socios-estadio-admin/CLAUDE.md`](https://github.com/arnigon-holdings/app-socios-estadio-admin/blob/main/CLAUDE.md).
7. **If you'll touch infra (Terraform)**: read [`app-socios-estadio-docs/INFRASTRUCTURE.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/INFRASTRUCTURE.md) + explore local `infrastructure/`.
8. **Before committing**: run `git status` + `git diff` to verify what is staged, especially search for secrets (`git grep -E "AKIA|AIza"`).

**Expected agent output** (per AGENTS.md):

> Small, local, reversible changes. No over-engineering. No obvious comments. Tests when applicable. Report what was done, what was verified, what remains pending.