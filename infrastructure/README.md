# `infrastructure/` — Terraform

All project infrastructure lives here, split by **who consumes it** (not by cloud).

> **Why not by cloud**: AWS has resources for the backend (S3 + Rekognition) and for the frontend (API Gateway + Lambda + Cognito). GCP does not have Terraform code deployed yet (the GCP phase is planned in [`app-socios-estadio-docs/INFRASTRUCTURE.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/INFRASTRUCTURE.md)). Splitting by domain makes it clearer which resource belongs to which service.

## Structure

```
infrastructure/
├── aws/                  ← AWS resources consumed by the BACKEND (Rails)
│   ├── main.tf           ← provider + S3 bucket + Rekognition collection + IAM role (inline)
│   ├── modules/{s3,rekognition}/
│   └── README.md         ← (next)
│
└── frontend-liveness/    ← AWS resources consumed by the FRONTEND (browser)
    ├── main.tf           ← provider + API Gateway + Lambda + Cognito + (optional Lightsail)
    ├── modules/{apigateway,lambda,cognito,iam,lightsail}/
    └── README.md         ← detailed
```

## Who consumes what?

### `infrastructure/aws/`

Used by the **Rails backend** (`backend/`) and the **Go face-search service** (`face-search-service/`) running on Cloud Run.

| Resource | Consumed by |
|---|---|
| S3 bucket `perfilamiento-faces` | `S3Uploader` (Rails) uploads reference + audit photos; Go service generates presigned URLs |
| Rekognition collection `socios_stadium_users` | `FaceIndexer` (Rails) runs `IndexFaces`; Go service runs `SearchFacesByImage` |
| IAM role | Cloud Run service account (Rails + Go) |

### `infrastructure/frontend-liveness/`

Consumed by the **frontend SPA** (`frontend/`) in the browser, via the AWS Amplify SDK.

| Resource | Consumed by |
|---|---|
| API Gateway | Vite dev proxy (`vite.config.ts`) + Amplify SDK in prod |
| Lambda functions | Support for the Face Liveness flow (create session + get results + signed URL) |
| Cognito Identity Pool + User Pool | Amplify SDK for credential vending |
| IAM | Roles for Lambda + API Gateway |
| Lightsail (optional) | Relay instance for WebSocket streaming (alternative to API Gateway) |

## Naming convention

- Directory in singular (`aws/`, `frontend-liveness/`), not by cloud provider — because there may be GCP infrastructure in the future that does not fit under `aws/`.
- Suffix `-liveness` when the domain is specific (e.g.: `frontend-liveness/`).

## Status

- ✅ `infrastructure/aws/` — deployed in dev.
- ✅ `infrastructure/frontend-liveness/` — deployed in dev.
- ⏳ GCP (Cloud SQL + Cloud Run + Memorystore) — pending, see [`app-socios-estadio-docs/INFRASTRUCTURE.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/INFRASTRUCTURE.md) section 4.

## Local deploy

Each subdirectory has its own `.terraform/` and state. To avoid mixing them:

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

See [`app-socios-estadio-docs/INFRASTRUCTURE.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/INFRASTRUCTURE.md) section 7 for Makefile targets (`make tf-plan-aws`, etc.).

---

## See also

| File | Purpose |
|---|---|
| [`../README.md`](../README.md) | Project entry point — stack, quickstart, conventions, polyrepo map |
| [`../AGENTS.md`](../AGENTS.md) | Operational rules for agents (must-read before any infra change) |
| [`../docs/ARQUITECTURA.md`](../docs/ARQUITECTURA.md) | Architecture diagrams — what each cloud resource above is used for in the flows |
| [`./frontend-liveness/README.md`](./frontend-liveness/README.md) | Face Liveness module detail (API Gateway + Lambda + Cognito) |
| [`app-socios-estadio-docs/INFRASTRUCTURE.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/INFRASTRUCTURE.md) | Full infrastructure doc (docs repo) |