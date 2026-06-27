# CHECKLIST.md — Progreso del Proyecto

> Estado actualizado: 2026-06-26
> Convenciones: ✅ completado · 🟡 en progreso · ❌ pendiente

---

## Resumen de Fases

| Fase | Nombre | Estado |
|------|--------|--------|
| M0 | Setup, infrastructure | ✅ |
| M1 | Registro público (RUT, phone, password, liveness) | ✅ |
| M2 | Admin panel (CRUD users, teams, points) | ✅ |
| M3 | Seguridad (JWT, rate limiting, CORS) | ✅ |
| M4 | Preparado Fase 2 (points ledger) | ✅ |
| M5 | Face Search System (S3 + Rekognition + Go Service) | ✅ |
| Phase 2 | Twilio, Referrals, Badges | ❌ pendiente |

---

## M1 — Registro Público

### Frontend
| Item | Estado | Notas |
|------|--------|-------|
| Wizard 7 pasos | ✅ | RUT → Teléfono → Password → Face Liveness → Equipos → Consents → Submit |
| Face Liveness | ✅ | `disableStartScreen`, confidence oculto al usuario, progress bar |
| Validación RUT (módulo 11) | ✅ | Permite numéricos y K; helper compartido en `frontend/src/lib/rut.ts` |
| Envío `audit_images[]` al backend | ✅ | 2026-06-25 |
| Oval del detector sin rectángulo blanco | ✅ | 2026-06-26 (`index.css`: `bg-transparent`, `border: none`, `box-shadow: none`) |

### Backend (Rails)
| Item | Estado | Notas |
|------|--------|-------|
| POST `/api/v1/frontend/users` | ✅ | |
| Recepción `photo` (base64) | ✅ | |
| Validación consentimientos | ✅ | |
| Storage local (fotos) | ✅ | `storage/uploads/` |
| Recepción `audit_images[]` | ✅ | 2026-06-26 |
| S3 upload | ✅ | `S3Uploader` → bucket `perfilamiento-faces` |
| Index en colección de caras | ✅ | `FaceIndexer` → `external_image_id = user.id` |
| Tabla `face_records` | ✅ | 2026-06-26 |
| Columna `users.indexed_at` | ✅ | 2026-06-26 |

---

## M2 — Admin Panel

| Item | Estado | Notas |
|------|--------|-------|
| Dashboard stats | ✅ | |
| CRUD users | ✅ | |
| CRUD teams | ✅ | |
| CRUD point_actions | ✅ | |
| Ledger transactions | ✅ | |
| Audit logs | ✅ | |
| Face search page | ✅ | Admin → Go service directo (Bearer). Layout 2 columnas, thumbnails con URL firmada 1h, bandas de similitud |

---

## M3 — Seguridad

| Item | Estado | Notas |
|------|--------|-------|
| JWT (access 1h, refresh 30d) | ✅ | |
| Rate limiting (rack-attack) | ✅ | |
| CORS configurado (Rails) | ✅ | |
| CORS allowlist (Go service) | ✅ | `CORS_ORIGINS` env, middleware dedicado |

---

## M5 — Face Search System

### Terraform backend (`infrastructure/aws/`)
| Item | Estado | Notas |
|------|--------|-------|
| S3 bucket `perfilamiento-faces` | ✅ | |
| Rekognition collection `socios_stadium_users` | ✅ | |
| IAM role (S3 + Rekognition) | ✅ | |

### Terraform frontend (`infrastructure/frontend-liveness/`)
| Item | Estado | Notas |
|------|--------|-------|
| Lambda `face-liveness-create-session` | ✅ | |
| Lambda `face-liveness-get-results` | ✅ | |
| API Gateway | ✅ | ID: `a8rgaq8bv0` |
| API Key | ✅ | |
| Cognito IAM role | ✅ | `rekognition:StartFaceLivenessSession` |
| Módulo `s3` | ✅ | bucket privado, versionado, SSE-S3, lifecycle, public access block |
| Módulo `rekognition` | ✅ | colección `socios_stadium_users` |
| IAM policy `face-indexing` | ✅ | least-privilege, scoped a bucket y colección, con `aws:ResourceAccount` |
| IAM role `face-indexing` | ✅ | assummable por EC2/ECS/Lambda + GCP WIF |

### Go Service (`face-search-service/`)
| Item | Estado | Notas |
|------|--------|-------|
| Estructura base | ✅ | `cmd/server`, `internal/{config,db,handlers,middleware,rekognition}` |
| Config desde env vars | ✅ | AWS, PostgreSQL, PORT, FACE_SEARCH_TOKEN, CORS_ORIGINS |
| GET `/health` | ✅ | |
| POST `/search-face` | ✅ | SearchFacesByImage, threshold 96% |
| Respuesta con `photo_url` (presigned 1h) | ✅ | 2026-06-26 |
| Mapeo de errores tipados AWS | ✅ | 2026-06-26 (`smithy.APIError` → mensaje user-friendly) |
| Dockerfile multi-stage | ✅ | `golang:1.24-alpine`, incluye `ca-certificates` (TLS a AWS funciona) |
| Cloud Build config | ✅ | `cloudbuild.yaml` |
| Docker Compose integrado | ✅ | `backend/docker-compose.yml` |
| Middleware CORS allowlist | ✅ | 2026-06-26 |

### Flujo end-to-end
| Item | Estado | Notas |
|------|--------|-------|
| Registro → Rails | ✅ | Foto guardada local + `face_records` |
| Rails → S3 | ✅ | `users/<id>/reference/`, `users/<id>/audit/` |
| Rails → Index en colección | ✅ | `external_image_id = user.id` |
| Admin → Go service → búsqueda | ✅ | Thumbnail en cada match, confianza en % y banda |

---

## Pendientes antes de Production

### Backend (Rails)
| Item | Prioridad |
|------|-----------|
| Tests unitarios `FaceIndexer` + `S3Uploader` | Media |
| Retry con backoff para index/búsqueda | Media |
| Circuit breaker | Baja |
| Mover credenciales AWS fuera de `docker-compose.yml` | Alta (seguridad) |

### Go Service
| Item | Prioridad |
|------|-----------|
| Tests unitarios | Media |
| Circuit breaker | Media |
| Retry con backoff | Media |

### Terraform / Infra
| Item | Prioridad |
|------|-----------|
| State remoto S3 + DynamoDB lock | Alta (sigue siendo local) |
| Módulo `iam` separado | Baja |
| KMS encryption en bucket | Baja (SSE-S3 ya activa) |

### Frontend / UX
| Item | Prioridad |
|------|-----------|
| i18n (inglés/portugués) | Baja |
| Dark mode | Baja |
| Onboarding post-OTP | Alta |

---

## Phase 2 (post-production)

| Feature | Prioridad |
|---------|-----------|
| Twilio WhatsApp Business | Alta |
| Sistema Referrals | Alta |
| Email transaccional | Baja |
| Notificaciones push (Firebase) | Media |

---

## Servicios Locales

| Servicio | URL/Puerto |
|----------|------------|
| Frontend usuarios | http://localhost:5173 |
| Admin panel | http://localhost:5174 |
| Rails API | http://localhost:3000 |
| Go service (face search) | http://localhost:8081 |
| PostgreSQL (docker) | localhost:5432 |
| Redis (docker) | localhost:6380 |

---

## Variables de Entorno

> **Las credenciales reales nunca deben commitearse.** Ver `.env.example` por plantilla.

### Backend Rails
```
DATABASE_URL=postgres://app_perfil:dev_password@postgres:5432/app_perfil_development?sslmode=disable
REDIS_URL=redis://redis:6379/1
RAILS_ENV=development
JWT_SECRET_KEY=<generate-256-bit>
CORS_ORIGINS=http://localhost:5173,http://localhost:5174
AWS_REGION=us-east-1
AWS_S3_BUCKET_NAME=perfilamiento-faces
REKOGNITION_COLLECTION_ID=socios_stadium_users
```

### Go service
```
DATABASE_URL=postgres://app_perfil:dev_password@localhost:5432/app_perfil_development?sslmode=disable
FACE_SEARCH_TOKEN=<secret-compartido-con-admin-panel>
REKOGNITION_COLLECTION_ID=socios_stadium_users
PORT=8080
CORS_ORIGINS=http://localhost:5173,http://localhost:5174
```

### Terraform (`infrastructure/aws/variables.tf`)
```
aws_region = "us-east-1"
s3_bucket_name = "perfilamiento-faces"
rekognition_collection_id = "socios_stadium_users"
```

