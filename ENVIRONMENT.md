# ENVIRONMENT.md — App Socios Estadio

## 1. Variables backend (`backend/`)

```bash
# DB (Cloud SQL)
DATABASE_URL=postgresql://user:pass@/db?host=/cloudsql/instance

# Redis (Memorystore)
REDIS_URL=rediss://user:pass@/0?addr=instance:6379

# JWT
JWT_SECRET_KEY=<generate-256-bit>
JWT_ACCESS_EXPIRATION=3600       # 1h
JWT_REFRESH_EXPIRATION=2592000   # 30d

# CORS
CORS_ORIGINS=https://admin.appservicios.cl,https://app.appservicios.cl

# AWS Rekognition + S3
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=<key>
AWS_SECRET_ACCESS_KEY=<secret>
AWS_S3_BUCKET_NAME=perfilamiento-faces
REKOGNITION_COLLECTION_ID=socios_stadium_users

# Twilio (fase 2)
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_WHATSAPP_FROM=
```

> Las credenciales reales nunca deben commitearse.  
> Mantener `.env`, usar `.env.example` como referencia.

---

## 2. Variables Go service (`face-search-service/`)

```bash
# AWS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=<key>
AWS_SECRET_ACCESS_KEY=<secret>

# DB
DATABASE_URL=postgres://user:pass@localhost:5432/perfilamiento

# Servicio
PORT=8080
FACE_SEARCH_TOKEN=<secret-token-compartido-con-admin-panel>
```

---

## 3. Frontend usuarios (`frontend/`)

```bash
VITE_API_BASE_URL=http://localhost:3000        # dev
VITE_API_BASE_URL=https://api.appservicios.cl  # prod
```

---

## 4. Admin panel (`admin/`)

```bash
VITE_API_BASE_URL=http://localhost:3000        # dev
VITE_API_BASE_URL=https://api.appservicios.cl  # prod
```

---

## 5. Seeds mínimas (dev)

No guardar credenciales reales aquí; solo ejemplo:

```text
admin@example.local / Admin123!
```

Para entornos reales, usar otros mecanismos (secret manager, etc.).
