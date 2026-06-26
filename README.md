# App Socios Estadio

Plataforma SaaS para registro de socios de un club deportivo con verificación facial y sistema de puntos. Los socios se registran vía web con liveness check (anti-spoof), se identifican en el estadio por cara (búsqueda facial en acceso), y acumulan puntos canjeables por beneficios.

> **Para agentes / LLMs / humanos nuevos en el proyecto**: leé este README primero, después `AGENTS.md` (reglas operativas), después el doc de tu subsistema (ver "Mapa de documentación" abajo).

---

## Stack

| Capa | Tecnología | Repositorio / path |
|---|---|---|
| Frontend usuarios (SPA) | React 19 + Vite + Tailwind v4 + shadcn/ui | `frontend/` |
| Admin panel (SPA) | React 19 + Vite + Tailwind v4 + shadcn/ui + TanStack Query | `admin/` |
| Backend API | Ruby on Rails 8 API-only + PostgreSQL + Redis | `backend/` |
| Face liveness (web) | AWS Lambda + API Gateway (FaceLiveness con Amplify SDK) | `frontend/terraform/` |
| Face indexing (S3 + Rekognition) | Rails (`S3Uploader` + `FaceIndexer`) | `backend/` |
| Face search (búsqueda + presigned) | Go 1.24 + AWS SDK v2 | `face-search-service/` |
| Infrastructure as code | Terraform (s3, rekognition, IAM modules) | `infrastructure/aws/` |
| DB prod | GCP Cloud SQL (PostgreSQL) | Terraform (futuro) |
| Host prod | GCP Cloud Run | Dockerfiles ya listos |

Cada subsistema es un **repositorio git independiente** dentro de esta raíz (polyrepo). El root tiene su propio `.git` con solo docs, `.gitignore`, `infrastructure/`.

---

## Quickstart (todo el stack, dev local)

Prerrequisitos: Docker, Node 20+, Ruby 3.4 (o usar Docker), AWS CLI configurado con credenciales de la cuenta de dev.

```bash
# 1. Clonar y entrar
git clone <repo-url> seguridad_estadio
cd seguridad_estadio

# 2. Backend: dependencias + DB
cd backend
docker compose up -d postgres redis        # solo infraestructura
docker compose run --rm app bundle install  # gems
docker compose run --rm app bundle exec rails db:migrate db:seed
cd ..

# 3. Backend: credenciales AWS en .env (gitignored)
cp backend/.env.example backend/.env.aws
# editar backend/.env.aws con AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY reales

# 4. Levantar backend completo (incluye face-search Go)
cd backend && docker compose up -d
cd ..

# 5. Frontends (otro terminal cada uno)
cd frontend && npm install && npm run dev    # http://localhost:5173
cd admin && npm install && npm run dev        # http://localhost:5174

# 6. Smoke test
curl -s http://localhost:3000/up            # rails health
curl -s http://localhost:8081/health        # go health
```

**Login admin por defecto** (seed): `admin@appperfil.cl` / `Admin123!`

---

## Mapa de documentación

| Doc | Propósito | Cuándo leerlo |
|---|---|---|
| [`AGENTS.md`](./AGENTS.md) | Reglas operativas del agente: workflow, comunicación, principios de implementación, regla de UX "ocultar capa tecnológica", harness engineering | **Siempre primero** |
| [`SPEC.md`](./SPEC.md) | Verdad funcional: qué hace el producto (registro, admin, búsqueda, puntos) | Al entender alcance |
| [`ARCHITECTURE.md`](./ARCHITECTURE.md) | Boundaries por componente (frontend ↔ backend ↔ Go service), capas (domain/application/infrastructure), diagramas | Al diseñar features nuevas |
| [`INFRASTRUCTURE.md`](./INFRASTRUCTURE.md) | Principios de infra, Terraform, IAM, deploy (GCP Cloud Run, Cloud SQL) | Al tocar infra o deploy |
| [`CHECKLIST.md`](./CHECKLIST.md) | Estado de fases M0-M5 + Phase 2, qué falta, prioridades | Al planificar trabajo |
| [`ENVIRONMENT.md`](./ENVIRONMENT.md) | Variables de entorno backend (referencia) | Al configurar entorno |
| [`HARNESS.md`](./HARNESS.md) | Marco de harness engineering (feedforward/feedback) | Contexto conceptual |
| `backend/CLAUDE.md` (no existe, ver AGENTS.md) | — | — |
| [`frontend/CLAUDE.md`](./frontend/CLAUDE.md) | Contexto del frontend: liveness UX, decisiones de wizard | Al trabajar en `frontend/` |
| [`admin/CLAUDE.md`](./admin/CLAUDE.md) | Contexto del admin: rutas, decisiones de tablas vs cards | Al trabajar en `admin/` |
| [`backend/README.md`](./backend/README.md) | Comandos específicos del backend | Al levantar/testear Rails |
| [`face-search-service/README.md`](./face-search-service/README.md) | Comandos del servicio Go | Al levantar/testear Go |
| [`infrastructure/aws/`](./infrastructure/aws/) | Terraform de S3 + Rekognition + IAM | Al cambiar infra AWS |

---

## Estructura del repo

```
.
├── README.md                  ← este archivo
├── AGENTS.md                  ← reglas operativas (LEER PRIMERO)
├── SPEC.md                    ← verdad funcional
├── ARCHITECTURE.md            ← boundaries
├── INFRASTRUCTURE.md          ← Terraform + cloud
├── CHECKLIST.md               ← fases M0-M5 + pendientes
├── ENVIRONMENT.md             ← env vars backend
├── HARNESS.md                 ← marco de harness engineering
├── Makefile                   ← targets comunes (lint, test, validate)
│
├── backend/                   ← Rails 8 API (polyrepo, propio .git)
│   ├── app/
│   ├── db/
│   ├── docker-compose.yml     ← postgres + redis + app + face-search
│   └── .env.aws               ← (gitignored) AWS IAM keys
│
├── face-search-service/       ← Go 1.24 (polyrepo, propio .git)
│   ├── cmd/server/main.go
│   ├── internal/{config,db,handlers,middleware,rekognition}/
│   ├── Dockerfile             ← golang:1.24-alpine + ca-certificates
│   └── .env.example            ← (tracked) template
│
├── frontend/                  ← React SPA socios (polyrepo, propio .git)
│   ├── src/
│   ├── terraform/              ← Lambda + API Gateway (Face Liveness)
│   ├── .env.example            ← (tracked) template
│   └── .env                    ← (gitignored) dev secrets
│
├── admin/                     ← React SPA admin (polyrepo, propio .git)
│   ├── src/
│   ├── .env.example            ← (tracked) template
│   └── .env.local              ← (gitignored) dev secrets
│
└── infrastructure/aws/        ← Terraform de M5 (tracked en root)
    ├── main.tf                ← provider + s3 + rekognition + IAM
    ├── variables.tf
    ├── outputs.tf
    └── modules/{s3,rekognition}/
```

---

## Convenciones del proyecto

### Reglas operativas (resumen; ver AGENTS.md completo)

- **Calidad > eficiencia > seguridad > agregar código nuevo**.
- **KISS primero**, DRY solo cuando haya duplicación real.
- **Borrar código obsoleto, no comentarlo**.
- **No abstraer por anticipación**.
- **Cambios pequeños, locales y reversibles**.
- Cada subsistema es un **polyrepo git independiente** — los commits van al repo del subsistema, no al root.

### Regla de UX: ocultar la capa tecnológica

**Ningún texto visible al usuario (socio, admin, o cualquier rol) puede mencionar proveedores ni servicios de infraestructura**: AWS, GCP, Azure, Rekognition, S3, Cloud SQL, Lambda, Cloud Run, etc. Mensajes user-facing describen comportamiento, no marca:

- ❌ `"Buscando coincidencias en Rekognition…"`
- ✅ `"Buscando coincidencias…"`

- ❌ `"Conectando con servicios de AWS..."`
- ✅ `"Conectando con el servicio de verificación..."`

**Excepción permitida**: nombres de campos internos del contrato API (`rekognition_face_id`, `s3_key`) sí pueden existir en types/JSON, no se muestran al usuario.

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
docker compose up -d                       # levanta todo (postgres + redis + app + face-search)
docker compose logs -f app                 # logs Rails
docker compose logs -f face-search         # logs Go
docker compose run --rm app bundle exec rails db:migrate db:seed
docker compose run --rm app bundle exec rails console
docker compose run --rm app bundle exec rubocop
docker compose run --rm app bundle exec rails test

# Frontend
cd frontend && npm run dev                 # http://localhost:5173
cd admin && npm run dev                    # http://localhost:5174

# Terraform (S3 + Rekognition + IAM)
cd infrastructure/aws
terraform init
terraform plan
terraform apply

# Tests del sistema (E2E manual)
# 1. Registrar un socio vía http://localhost:5173/registro (7 pasos, liveness OK)
# 2. Login admin en http://localhost:5174
# 3. Ir a "Búsqueda Facial", subir foto -> buscar match
```

---

## Estado actual

Ver [`CHECKLIST.md`](./CHECKLIST.md). TL;DR:

- **M0-M5 ✅**: setup, registro público, admin, seguridad, búsqueda facial.
- **Pendiente alta**: rotar credenciales AWS filtradas en git history (ver CHECKLIST).
- **Pendiente media**: tests unitarios (`FaceIndexer`, `S3Uploader`, Go service), retry/backoff, Terraform state remoto.
- **Phase 2**: Twilio WhatsApp, referrals, email transaccional.

---

## Para LLMs que arrancan en el proyecto

1. **Leé este README** (orientación general).
2. **Leé [`AGENTS.md`](./AGENTS.md)** (reglas operativas — no negociables).
3. **Leé [`SPEC.md`](./SPEC.md)** (qué hace el producto).
4. **Leé [`ARCHITECTURE.md`](./ARCHITECTURE.md)** (boundaries — qué puede tocar tu subsistema).
5. **Si vas a tocar `frontend/`**: leé también [`frontend/CLAUDE.md`](./frontend/CLAUDE.md).
6. **Si vas a tocar `admin/`**: leé también [`admin/CLAUDE.md`](./admin/CLAUDE.md).
7. **Si vas a tocar infra (Terraform)**: leé [`INFRASTRUCTURE.md`](./INFRASTRUCTURE.md).
8. **Antes de commitear**: corré `git status` + `git diff` para verificar qué entra, especialmente buscar secrets (`git grep -E "AKIA|AIza"`).

**Output esperado del agente** (per AGENTS.md):
> Cambios pequeños, locales y reversibles. Sin sobreingeniería. Sin comentarios obvios. Tests cuando aplica. Reportar qué se hizo, qué se verificó, qué queda pendiente.
