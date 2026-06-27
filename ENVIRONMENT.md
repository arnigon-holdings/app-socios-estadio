# ENVIRONMENT.md — App Socios Estadio

> **Documentación completa por proyecto** (con defaults, dónde se carga cada var, y dónde cambiarla): ver `backend/README.md`, `frontend/README.md`, `admin/README.md`, `face-search-service/README.md`.
>
> Este archivo es una referencia rápida consolidada.

---

## 1. Variables backend (`backend/`)

```bash
# Core
RAILS_ENV=development
SECRET_KEY_BASE=<generate-with-rails-secret>           # >= 64 chars
JWT_SECRET_KEY=<generate-256-bit>                       # >= 32 chars

# DB (Cloud SQL en prod, local docker en dev)
DATABASE_URL=postgresql://user:pass@/db?host=/cloudsql/instance
# Alternativa: DB_HOST + DB_PORT + DB_USER + DB_PASSWORD

# Redis (Memorystore)
REDIS_URL=rediss://user:pass@/0?addr=instance:6379

# CORS
CORS_ORIGINS=https://admin.appservicios.cl,https://app.appservicios.cl

# AWS Rekognition + S3
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=<key>            # solo dev; prod usa IAM role
AWS_SECRET_ACCESS_KEY=<secret>      # solo dev; prod usa IAM role
AWS_S3_BUCKET_NAME=perfilamiento-faces
REKOGNITION_COLLECTION_ID=socios_stadium_users
ACTIVE_STORAGE_SERVICE=local        # "local" (dev) | "r2" (prod, Cloudflare R2)

# Seeds admin (solo dev — NUNCA en prod)
SEED_ADMIN_EMAIL=admin@appperfil.cl
SEED_ADMIN_PASSWORD=Admin123!
SEED_OPERATOR_EMAIL=operador@appperfil.cl
SEED_OPERATOR_PASSWORD=Operador123!
SEED_SUPPORT_EMAIL=soporte@appperfil.cl
SEED_SUPPORT_PASSWORD=Soporte123!
```

> Credenciales reales nunca deben commitearse. Mantener en `.env` (gitignored) o Secret Manager (prod).  
> Ver `backend/.env.example` para el template completo con descripciones.

---

## 2. Variables Go service (`face-search-service/`)

```bash
# Server
PORT=8080

# Auth
FACE_SEARCH_TOKEN=<secret-token-compartido-con-admin-panel>
CORS_ORIGINS=http://localhost:5174                    # o CSV para prod

# AWS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=<key>            # solo dev; prod usa IAM role
AWS_SECRET_ACCESS_KEY=<secret>      # solo dev; prod usa IAM role
AWS_S3_BUCKET_NAME=perfilamiento-faces
REKOGNITION_COLLECTION_ID=socios_stadium_users

# DB
DATABASE_URL=postgres://user:pass@host:5432/db?sslmode=disable
```

> Ver `face-search-service/.env.example` para el template completo.

---

## 3. Frontend usuarios (`frontend/`)

```bash
# Backend API
VITE_API_BASE_URL=http://localhost:3000        # dev
VITE_API_BASE_URL=https://api.appservicios.cl  # prod

# AWS region
VITE_AWS_REGION=us-east-1

# Face Liveness (API Gateway)
VITE_FACE_LIVENESS_API_URL=https://<id>.execute-api.us-east-1.amazonaws.com/prod/face-liveness
VITE_FACE_LIVENESS_API_KEY=<api-gateway-key>

# Cognito (Amplify SDK)
VITE_COGNITO_IDENTITY_POOL_ID=us-east-1:<guid>
VITE_COGNITO_USER_POOL_ID=us-east-1_<alnum>
VITE_COGNITO_USER_POOL_CLIENT_ID=<alnum>

# Go face-search (opcional, solo si frontend llama directo al Go service)
VITE_FACE_SEARCH_URL=http://localhost:8081
VITE_FACE_SEARCH_TOKEN=<compartido-con-face-search-service>
```

> Ver `frontend/.env.example` para el template completo.

---

## 4. Admin panel (`admin/`)

```bash
# Backend API
VITE_API_BASE_URL=http://localhost:3000        # dev
VITE_API_BASE_URL=https://api.appservicios.cl  # prod

# Go face-search service
VITE_FACE_SEARCH_URL=http://localhost:8081     # dev
VITE_FACE_SEARCH_URL=https://face-search-run.hereiam.run  # prod
VITE_FACE_SEARCH_TOKEN=<compartido-con-face-search-service>

# Placeholder UI (opcional, solo dev)
VITE_ADMIN_EMAIL=admin@appperfil.cl
VITE_ADMIN_PASSWORD=Admin123!
```

> Ver `admin/.env.example` para el template completo.

---

## 5. Archivos de configuración

| Proyecto | Template (tracked) | Dev defaults (tracked, sin secretos) | Secrets reales (gitignored) |
|---|---|---|---|
| backend | `backend/.env.example` | `backend/.env.development` | `backend/.env`, `backend/.env.aws`, `backend/.env.production` |
| frontend | `frontend/.env.example` | `frontend/.env.development` | `frontend/.env`, `frontend/.env.local`, `frontend/.env.production` |
| admin | `admin/.env.example` | `admin/.env.development` | `admin/.env`, `admin/.env.local`, `admin/.env.production` |
| face-search-service | `face-search-service/.env.example` | `face-search-service/.env.development` | `face-search-service/.env`, `face-search-service/.env.production` |
| infrastructure (Terraform) | `infrastructure/*/variables.tf` (defaults en código) | n/a | `infrastructure/*/*.tfvars` (gitignored por `.gitignore` raíz) |

> Los `.env.development` son tracked y funcionan out-of-the-box con defaults seguros (sin secretos reales). En prod, override via Secret Manager / env vars del Cloud Run service.
> 
> **Terraform**: los secretos sensibles van en `*.tfvars` (gitignored por el `.gitignore` raíz). Cada directorio en `infrastructure/` (ej: `infrastructure/frontend-liveness/`) tiene su propio `.gitignore` que excluye `.terraform/`, state files, y tfvars.
