# `infrastructure/` — Terraform

Toda la infra del proyecto vive acá, separada por **quién la consume** (no por cloud).

> **Por qué no por cloud**: AWS tiene recursos para backend (S3 + Rekognition) y para frontend (API Gateway + Lambda + Cognito). GCP todavía no tiene código Terraform desplegado (la fase GCP está planificada en `INFRASTRUCTURE.md` raíz). Separar por dominio hace más claro qué recurso es para qué servicio.

## Estructura

```
infrastructure/
├── aws/                  ← Recursos AWS consumidos por el BACKEND (Rails)
│   ├── main.tf           ← provider + S3 bucket + Rekognition collection + IAM
│   ├── modules/{s3,rekognition,iam}/
│   └── README.md         ← (próximo)
│
└── frontend-liveness/    ← Recursos AWS consumidos por el FRONTEND (browser)
    ├── main.tf           ← provider + API Gateway + Lambda + Cognito + (Lightsail opcional)
    ├── modules/{apigateway,lambda,cognito,iam,lightsail}/
    └── README.md         ← detallado
```

## ¿Quién consume qué?

### `infrastructure/aws/`

Lo usa el **backend Rails** (`backend/`) y el **Go face-search service** (`face-search-service/`) corriendo en Cloud Run.

| Recurso | Lo consume |
|---|---|
| S3 bucket `perfilamiento-faces` | `S3Uploader` (Rails) sube fotos de referencia + audit; Go service genera presigned URLs |
| Rekognition collection `socios_stadium_users` | `FaceIndexer` (Rails) hace `IndexFaces`; Go service hace `SearchFacesByImage` |
| IAM role | Service account de Cloud Run (Rails + Go) |

### `infrastructure/frontend-liveness/`

Lo consume el **frontend SPA** (`frontend/`) en el browser, vía AWS Amplify SDK.

| Recurso | Lo consume |
|---|---|
| API Gateway | Vite dev proxy (`vite.config.ts`) + Amplify SDK en prod |
| Lambda functions | Soporte del flow de Face Liveness (create session + get results + signed URL) |
| Cognito Identity Pool + User Pool | Amplify SDK para credential vending |
| IAM | Roles para Lambda + API Gateway |
| Lightsail (opcional) | Relay instance para WebSocket streaming (alternativa a API Gateway) |

## Convención de nombres

- Directorio en singular (`aws/`, `frontend-liveness/`), no por cloud provider — porque puede haber infra GCP en el futuro que no encaje en `aws/`.
- Sufijo `-liveness` cuando el dominio es específico (ej: `frontend-liveness/`).

## Estado

- ✅ `infrastructure/aws/` — desplegado en dev.
- ✅ `infrastructure/frontend-liveness/` — desplegado en dev.
- ⏳ GCP (Cloud SQL + Cloud Run + Memorystore) — pendiente, ver `../../INFRASTRUCTURE.md` raíz sección 4.

## Deploy local

Cada subdirectorio tiene su propio `.terraform/` y state. Para no mezclarlos:

```bash
# Backend infra
cd infrastructure/aws
terraform init
terraform plan

# Frontend infra
cd ../frontend-liveness
terraform init
terraform plan
```

Ver `INFRASTRUCTURE.md` raíz para los targets de Makefile (`make tf-plan-aws`, etc.).