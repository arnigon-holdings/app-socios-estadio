# `infrastructure/frontend-liveness/` — Terraform (Face Liveness)

Terraform para el backend de Face Liveness que usa el **frontend** (registro de socios, wizard paso 4).

## ¿Qué despliega?

- **API Gateway** (`modules/apigateway/`): REST API con API key + usage plan + stage `prod`.
- **Lambda** (`modules/lambda/`): 3 funciones Python que dan soporte al Face Liveness.
  - `create_session.py` — crea la sesión Rekognition.
  - `get_results.py` — devuelve el resultado de liveness.
  - `get_signed_streaming_url.py` — config del streaming URL.
- **Cognito** (`modules/cognito/`): Identity Pool + User Pool + Client que el SDK de Amplify consume desde el browser.
- **IAM** (`modules/iam/`): roles y policies para Lambda + API Gateway (least privilege).
- **Lightsail** (`modules/lightsail/`): [opcional] instancia relay como alternativa a API Gateway WebSocket directo. No se usa en prod actualmente.

## Diferencia con `infrastructure/aws/`

| Directorio | Para quién | Recursos |
|---|---|---|
| `infrastructure/aws/` | **backend** (Rails) | S3 (fotos), Rekognition collection, IAM del Rails service |
| `infrastructure/frontend-liveness/` | **frontend** (browser) | API Gateway, Lambda (Rekognition control plane), Cognito, Lightsail |

> La colección Rekognition (`socios_stadium_users`) y el bucket S3 (`perfilamiento-faces`) son recursos **del backend** pero el frontend los referencia vía env vars (`VITE_FACE_LIVENESS_API_URL`, `VITE_COGNITO_*`).

## Outputs consumidos por el frontend

Después de `terraform apply`:

| Output | Env var del frontend | Propósito |
|---|---|---|
| `api_gateway_url` | `VITE_FACE_LIVENESS_API_URL` | URL completa del API Gateway (Vite dev proxy + Amplify SDK en prod) |
| `api_key_value` | `VITE_FACE_LIVENESS_API_KEY` | API key enviada como header `X-Api-Key` |
| `cognito_identity_pool_id` | `VITE_COGNITO_IDENTITY_POOL_ID` | Identity Pool del Amplify SDK |
| `cognito_user_pool_id` | `VITE_COGNITO_USER_POOL_ID` | User Pool |
| `cognito_user_pool_client_id` | `VITE_COGNITO_USER_POOL_CLIENT_ID` | User Pool Client |

Ver [`../../frontend/README.md`](../../frontend/README.md) para el lado consumidor.

## Deploy

```bash
cd infrastructure/frontend-liveness
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Variables sensibles (`api_key_name`, etc.) van en `terraform.tfvars` (gitignored — ver `.gitignore` raíz).

## Archivos ignorados

- `.terraform/` — cache local
- `*.tfstate*` — state file (en prod mover a S3 con backend remoto)
- `*.tfvars` — variables con valores reales
- `modules/lambda/src/*.zip` — build artifact (Terraform lo regenera con `data "archive_file"`)

Ver `.gitignore` del directorio.