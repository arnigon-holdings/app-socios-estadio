# `infrastructure/frontend-liveness/` — Terraform (Face Liveness)

Terraform for the Face Liveness backend used by the **frontend** (member registration, wizard step 4).

## What does it deploy?

- **API Gateway** (`modules/apigateway/`): REST API with API key + usage plan + `prod` stage.
- **Lambda** (`modules/lambda/`): 3 Python functions that support Face Liveness.
  - `create_session.py` — creates the Rekognition session.
  - `get_results.py` — returns the liveness result.
  - `get_signed_streaming_url.py` — streaming URL configuration.
- **Cognito** (`modules/cognito/`): Identity Pool + User Pool + Client that the Amplify SDK consumes from the browser.
- **IAM** (`modules/iam/`): roles and policies for Lambda + API Gateway (least privilege).
- **Lightsail** (`modules/lightsail/`): [optional] relay instance as an alternative to direct API Gateway WebSocket. Not used in prod currently.

## Difference with `infrastructure/aws/`

| Directory | For whom | Resources |
|---|---|---|
| `infrastructure/aws/` | **backend** (Rails) | S3 (photos), Rekognition collection, IAM for the Rails service |
| `infrastructure/frontend-liveness/` | **frontend** (browser) | API Gateway, Lambda (Rekognition control plane), Cognito, Lightsail |

> The Rekognition collection (`socios_stadium_users`) and the S3 bucket (`perfilamiento-faces`) are **backend** resources, but the frontend references them via env vars (`VITE_FACE_LIVENESS_API_URL`, `VITE_COGNITO_*`).

## Outputs consumed by the frontend

After `terraform apply`:

| Output | Frontend env var | Purpose |
|---|---|---|
| `api_gateway_url` | `VITE_FACE_LIVENESS_API_URL` | Full API Gateway URL (Vite dev proxy + Amplify SDK in prod) |
| `api_key_value` | `VITE_FACE_LIVENESS_API_KEY` | API key sent as the `X-Api-Key` header |
| `cognito_identity_pool_id` | `VITE_COGNITO_IDENTITY_POOL_ID` | Identity Pool for the Amplify SDK |
| `cognito_user_pool_id` | `VITE_COGNITO_USER_POOL_ID` | User Pool |
| `cognito_user_pool_client_id` | `VITE_COGNITO_USER_POOL_CLIENT_ID` | User Pool Client |

See [`../../frontend/README.md`](../../frontend/README.md) for the consumer side.

## Deploy

```bash
cd infrastructure/frontend-liveness
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Sensitive variables (`api_key_name`, etc.) live in `terraform.tfvars` (gitignored — see root `.gitignore`).

## Ignored files

- `.terraform/` — local cache
- `*.tfstate*` — state file (in prod move to S3 with a remote backend)
- `*.tfvars` — variables with real values
- `modules/lambda/src/*.zip` — build artifact (Terraform regenerates it with `data "archive_file"`)

See `.gitignore` in this directory.