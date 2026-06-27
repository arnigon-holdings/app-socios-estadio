# INFRASTRUCTURE.md — App Socios Estadio

## 1. Principios

- Toda infraestructura vía Terraform.
- Nada de scripts ad-hoc de producción como solución final.
- Infra separada por cloud (AWS vs GCP).
- State remoto por cloud (S3 para AWS, GCS para GCP).
- Variables y nombres de recursos parametrizados.

---

## 2. Estructura Terraform

La infra se separa por **quién la consume**, no por cloud. AWS tiene recursos para backend y frontend en stacks separados.

```txt
infrastructure/
├── aws/                     ← consumido por BACKEND (Rails + Go service)
│   ├── main.tf              ← provider + S3 + Rekognition + IAM del backend
│   ├── variables.tf
│   ├── outputs.tf
│   ├── *.tfvars             ← (gitignored)
│   └── modules/
│       ├── s3/              ← bucket de fotos de socios
│       ├── rekognition/     ← colección de caras indexadas
│       └── iam/             ← service account roles
│
├── frontend-liveness/       ← consumido por FRONTEND (browser, Amplify SDK)
│   ├── main.tf              ← provider + API Gateway + Lambda + Cognito
│   ├── variables.tf
│   ├── outputs.tf           ← outputs consumidos por frontend (api_url, api_key, cognito_*)
│   ├── *.tfvars             ← (gitignored)
│   └── modules/
│       ├── apigateway/      ← REST API + API key
│       ├── lambda/          ← 3 funciones Python (create_session, get_results, streaming)
│       ├── cognito/         ← Identity Pool + User Pool + Client
│       ├── iam/             ← roles para Lambda + API Gateway
│       └── lightsail/       ← (opcional) relay instance para WebSocket
│
└── gcp/                     ← (futuro) consumido por BACKEND en prod
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── modules/
        ├── cloud-sql/       ← PostgreSQL principal
        ├── cloud-run/       ← Rails API + Go service
        ├── memorystore/     ← Redis
        └── artifact-registry/
```

> Ver [`infrastructure/README.md`](./infrastructure/README.md) para el detalle de cada stack y qué servicio lo consume.

---

## 3. AWS

### 3.1 Servicios

- **Stack backend** (`infrastructure/aws/`):
  - S3: bucket privado para fotos (`perfilamiento-faces` en prod).
  - Rekognition Face Collection: `socios_stadium_users`.
  - IAM: service account role con permisos S3 + Rekognition (least privilege).
- **Stack frontend** (`infrastructure/frontend-liveness/`):
  - Lambda + API Gateway: Face Liveness (control plane para Rekognition).
  - Cognito: Identity Pool + User Pool para Amplify SDK.
  - Lightsail (opcional): relay para WebSocket streaming.
- **Go service** (Cloud Run): expone `POST /search-face` al admin panel. Auth vía bearer token (`FACE_SEARCH_TOKEN`). CORS allowlist vía `CORS_ORIGINS` (no usar `*`).

### 3.2 IAM (principio)

- Permitir mínimo necesario:
  - `s3:PutObject`, `s3:GetObject`.
  - `rekognition:IndexFaces`, `rekognition:SearchFacesByImage`.
- Nunca usar `Resource: "*"`, salvo en prototipos internos; en producción, restringir a recursos específicos.

---

## 4. GCP

### 4.1 Servicios

- Cloud SQL PostgreSQL: DB principal.
- Cloud Run: backend Rails y Go service.
- Memorystore Redis: cache + rate limiting.
- Cloud Build: CI/CD.

### 4.2 Conexión Cloud SQL

- Dev: Cloud SQL Auth Proxy.
- Prod: Cloud Run con `DATABASE_URL` usando host `/cloudsql/instance`.

---

## 5. Environments

- **Development**:
  - Docker Compose local para backend + Postgres + Redis.
- **Staging**:
  - GCP Cloud Run + Cloud SQL + Memorystore (pendiente definir).
- **Production**:
  - GCP Cloud Run + Cloud SQL + Memorystore.
  - Storage principal: S3 para fotos; otros assets pueden usar Cloud Storage / R2-compatible según decisión futura.

---

## 6. Patrones de resiliencia

- Retries con backoff para llamadas a AWS y Twilio.
- Circuit breakers en Go service y/o backend en llamadas críticas.
- Timeouts obligatorios para llamadas externas.
- Health checks en Cloud Run para backend y Go service.

---

## 7. Makefile (infra y dev)

Targets recomendados (ajustar a real):

```bash
make deps        # instalar dependencias
make fmt         # formatear código
make lint        # linters
make test        # tests
make validate    # fmt + lint + test

# Terraform
make tf-plan-aws
make tf-apply-aws
make tf-plan-gcp
make tf-apply-gcp
```
