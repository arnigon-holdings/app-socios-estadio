# `app-socios-estadio` — root

Plataforma SaaS para registro de socios de un club deportivo con verificación facial y sistema de puntos. Los socios se registran vía web con liveness check (anti-spoof), se identifican en el estadio por cara (búsqueda facial en acceso), y acumulan puntos canjeables por beneficios.

> **Para agentes / LLMs / humanos nuevos en el proyecto**: leé este README primero, después [`app-socios-estadio-docs/AGENTS.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/AGENTS.md) (reglas operativas), después el doc de tu subsistema (ver "Mapa de documentación" en el docs repo).

---

## Este repo (root)

El root contiene **solo** la infraestructura Terraform compartida y los entry points mínimos (`AGENTS.md` raíz + este `README.md` + `docs/`). Todo el código de aplicación y la documentación detallada (SPEC, ARCHITECTURE, INFRASTRUCTURE, CHECKLIST, ENVIRONMENT, HARNESS, Makefile) vive en repos separados.

## Mapa de repos del proyecto

| Repo | Contenido |
|---|---|
| [`arnigon-holdings/app-socios-estadio-infra`](https://github.com/arnigon-holdings/app-socios-estadio-infra) | **Este repo**: root + `infrastructure/` (Terraform) + `docs/` + `AGENTS.md` raíz |
| [`arnigon-holdings/app-socios-estadio-docs`](https://github.com/arnigon-holdings/app-socios-estadio-docs) | Documentación: AGENTS, ARCHITECTURE, SPEC, INFRASTRUCTURE, CHECKLIST, ENVIRONMENT, HARNESS, Makefile |
| [`arnigon-holdings/app-socios-estadio-backend`](https://github.com/arnigon-holdings/app-socios-estadio-backend) | Rails 8 API (polyrepo, propio .git) |
| [`arnigon-holdings/app-socios-estadio-frontend`](https://github.com/arnigon-holdings/app-socios-estadio-frontend) | React SPA socios (polyrepo, propio .git) |
| [`arnigon-holdings/app-socios-estadio-admin`](https://github.com/arnigon-holdings/app-socios-estadio-admin) | React SPA admin (polyrepo, propio .git) |
| [`arnigon-holdings/app-socios-estadio-face-search`](https://github.com/arnigon-holdings/app-socios-estadio-face-search) | Go service búsqueda facial (polyrepo, propio .git) |

> **Convencion polyrepo**: cada subsistema es un repo git independiente. El root tiene solo infra compartida + entry points. Ver [`app-socios-estadio-docs/`](https://github.com/arnigon-holdings/app-socios-estadio-docs) para la documentación completa.

## Stack

| Capa | Tecnología | Repo |
|---|---|---|
| Frontend usuarios (SPA) | React 19 + Vite + Tailwind v4 + shadcn/ui | `app-socios-estadio-frontend` |
| Admin panel (SPA) | React 19 + Vite + Tailwind v4 + shadcn/ui + TanStack Query | `app-socios-estadio-admin` |
| Backend API | Ruby on Rails 8 API-only + PostgreSQL + Redis | `app-socios-estadio-backend` |
| Face liveness (web) | AWS Lambda + API Gateway + Cognito | `infrastructure/frontend-liveness/` (este repo) |
| Face indexing (S3 + Rekognition) | Rails (`S3Uploader` + `FaceIndexer`) | `app-socios-estadio-backend` |
| Face search (búsqueda + presigned) | Go 1.24 + AWS SDK v2 | `app-socios-estadio-face-search` |
| Infrastructure as code (backend AWS) | Terraform (S3 + Rekognition + IAM) | `infrastructure/aws/` (este repo) |
| Infrastructure as code (frontend AWS) | Terraform (API Gateway + Lambda + Cognito + IAM + Lightsail) | `infrastructure/frontend-liveness/` (este repo) |
| DB prod | GCP Cloud SQL (PostgreSQL) | Terraform (futuro) |
| Host prod | GCP Cloud Run | Dockerfiles ya listos |

## Estructura del root

```
.
├── README.md                  ← este archivo (entry point)
├── AGENTS.md                  ← reglas operativas raíz (resumen; versión completa en docs repo)
├── docs/
│   └── ARQUITECTURA.md        ← borrador en español (versión final en docs repo)
│
└── infrastructure/            ← Terraform compartido (tracked en este repo)
    ├── aws/                   ← backend AWS (S3 + Rekognition + IAM)
    │   ├── main.tf
    │   └── modules/{s3,rekognition}/
    └── frontend-liveness/     ← frontend AWS (API Gateway + Lambda + Cognito + IAM + Lightsail)
        ├── main.tf
        ├── README.md          ← qué despliega + outputs que consume el frontend
        └── modules/{apigateway,lambda,cognito,iam,lightsail}/
```

> Los 4 directorios de apps (`backend/`, `frontend/`, `admin/`, `face-search-service/`) **no viven en este repo**. Son polyrepos independientes con su propio `.git`. Si los ves localmente, son clones/worktrees que mantienen su propio historial.

---

## Quickstart (todo el stack, dev local)

Prerrequisitos: Docker, Node 20+, Ruby 3.4 (o usar Docker), AWS CLI configurado con credenciales de la cuenta de dev.

```bash
# 1. Clonar cada repo (polyrepo)
git clone https://github.com/arnigon-holdings/app-socios-estadio-infra.git
git clone https://github.com/arnigon-holdings/app-socios-estadio-backend.git backend
git clone https://github.com/arnigon-holdings/app-socios-estadio-frontend.git frontend
git clone https://github.com/arnigon-holdings/app-socios-estadio-admin.git admin
git clone https://github.com/arnigon-holdings/app-socios-estadio-face-search.git face-search-service
git clone https://github.com/arnigon-holdings/app-socios-estadio-docs.git  # opcional, para AGENTS.md

# 2. Backend: dependencias + DB
cd backend
docker compose up -d postgres redis
docker compose run --rm app bundle install
docker compose run --rm app bundle exec rails db:migrate db:seed
cd ..

# 3. Backend: credenciales AWS en .env (gitignored)
cp backend/.env.example backend/.env.aws
# editar backend/.env.aws con AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY reales

# 4. Levantar backend completo (incluye face-search Go)
cd backend && docker compose up -d && cd ..

# 5. Frontends (otro terminal cada uno)
cd frontend && npm install && npm run dev    # http://localhost:5173
cd admin && npm install && npm run dev        # http://localhost:5174

# 6. Smoke test
curl -s http://localhost:3000/up            # rails health
curl -s http://localhost:8081/health        # go health
```

**Login admin por defecto** (seed, configurable via `SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD` en `backend/.env.development`): defaults a `admin@appperfil.cl` / `Admin123!`.

---

## Documentación

Toda la documentación detallada (SPEC, ARCHITECTURE, INFRASTRUCTURE, CHECKLIST, ENVIRONMENT, HARNESS, Makefile) está en:

👉 **[`arnigon-holdings/app-socios-estadio-docs`](https://github.com/arnigon-holdings/app-socios-estadio-docs)**

Ahí vas a encontrar:
- Mapa de documentación por subsistema
- Reglas operativas para agentes (AGENTS.md)
- Verdad funcional (SPEC.md)
- Boundaries (ARCHITECTURE.md)
- Terraform overview (INFRASTRUCTURE.md)
- Estado del proyecto (CHECKLIST.md)
- Variables de entorno (ENVIRONMENT.md)
- Marco de trabajo (HARNESS.md)
- Comandos comunes (Makefile)

---

## Convenciones del proyecto

### Regla de UX: ocultar la capa tecnológica

Ningún texto visible al usuario (socio, admin, o cualquier rol) puede mencionar proveedores ni servicios de infraestructura: AWS, GCP, Azure, Rekognition, S3, Cloud SQL, Lambda, Cloud Run, etc. Mensajes user-facing describen comportamiento, no marca:

- ❌ `"Buscando coincidencias en Rekognition…"`
- ✅ `"Buscando coincidencias…"`
- ❌ `"Conectando con servicios de AWS..."`
- ✅ `"Conectando con el servicio de verificación..."`

Excepción permitida: nombres de campos internos del contrato API (`rekognition_face_id`, `s3_key`) sí pueden existir en types/JSON, no se muestran al usuario.

### Comunicación con el agente

- **Chat con humano**: conciso, directo, sin fluff. Estilo "caveman" según preferencia del owner.
- **Código, nombres, comentarios, tests, commits, PRs**: normal, legible, mantenible.
- **Sin emojis** salvo que el usuario los pida explícitamente.
- **Sin comentarios obvios** en código — el código debe ser self-explanatory; si necesita comentario, refactorizar.

### Seguridad

- **Nunca hardcodear credenciales**. Todo credential vive en `.env*` gitignored o en secret manager (producción).
- **No commitear `.env`, `.env.local`, `.env.aws`, `.env.production`, etc.** — `.gitignore` ya los cubre.
- **Verificar antes de commitear**: `git grep -E "AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}"` debería devolver vacío.
- **Validar inputs en bordes de entrada** (controllers, handlers Go, form schemas).
- **Permisos mínimos en AWS IAM** — `infrastructure/aws/main.tf` define policy con `aws:ResourceAccount` condition.

### Riesgo operativo

- **Read-only**: el agente opera sin confirmación.
- **Draft**: cambios con side effects externos simulables (Terraform plan, dry-run).
- **External write**: AWS / DB / APIs externas — requiere aprobación explícita del humano (`terraform apply`, `docker compose down -v`, git push, etc).

---

## Quick reference de comandos

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

## Estado actual

Ver [`app-socios-estadio-docs/CHECKLIST.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/CHECKLIST.md). TL;DR:

- **M0-M5 ✅**: setup, registro público, admin, seguridad, búsqueda facial.
- **Pendiente alta**: rotar credenciales AWS filtradas en git history (ver CHECKLIST).
- **Pendiente media**: tests unitarios (`FaceIndexer`, `S3Uploader`, Go service), retry/backoff, Terraform state remoto.
- **Phase 2**: Twilio WhatsApp, referrals, email transaccional.

---

## Para LLMs que arrancan en el proyecto

1. **Leé este README** (orientación general).
2. **Leé [`app-socios-estadio-docs/AGENTS.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/AGENTS.md)** (reglas operativas — no negociables).
3. **Leé [`app-socios-estadio-docs/SPEC.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/SPEC.md)** (qué hace el producto).
4. **Leé [`app-socios-estadio-docs/ARCHITECTURE.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/ARCHITECTURE.md)** (boundaries — qué puede tocar tu subsistema).
5. **Si vas a tocar frontend**: leé también [`app-socios-estadio-frontend/CLAUDE.md`](https://github.com/arnigon-holdings/app-socios-estadio-frontend/blob/main/CLAUDE.md).
6. **Si vas a tocar admin**: leé también [`app-socios-estadio-admin/CLAUDE.md`](https://github.com/arnigon-holdings/app-socios-estadio-admin/blob/main/CLAUDE.md).
7. **Si vas a tocar infra (Terraform)**: leé [`app-socios-estadio-docs/INFRASTRUCTURE.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/INFRASTRUCTURE.md) + explorá `infrastructure/` local.
8. **Antes de commitear**: corré `git status` + `git diff` para verificar qué entra, especialmente buscar secrets (`git grep -E "AKIA|AIza"`).

**Output esperado del agente** (per AGENTS.md):

> Cambios pequeños, locales y reversibles. Sin sobreingeniería. Sin comentarios obvios. Tests cuando aplica. Reportar qué se hizo, qué se verificó, qué queda pendiente.