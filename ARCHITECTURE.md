# ARCHITECTURE.md — App Socios Estadio

## 1. Repositorios y estructura

Raíz monorepo:

```txt
perfilamiento/
├── SPEC.md
├── AGENTS.md
├── HARNESS.md
├── ARCHITECTURE.md
├── INFRASTRUCTURE.md
├── ENVIRONMENT.md
├── Makefile
├── backend/               # Rails 8 API
├── frontend/              # React SPA usuarios
├── admin/                 # React SPA admin
└── face-search-service/   # Go service (Cloud Run)
```

> Nota: nombres consistentes:  
> - `backend/` = Rails 8 API  
> - `frontend/` = app usuarios  
> - `admin/` = admin panel  
> - `face-search-service/` = Go service búsqueda facial  

## 2. Stack por componente

### 2.1 Backend (`backend/`)

- Rails 8 API-only.
- PostgreSQL 16.
- Redis 7 (cache, rate limiting).
- Auth JWT (access 1h, refresh 30d) vía cookies httpOnly.
- Rack-attack para rate limiting.

### 2.2 Frontend usuarios (`frontend/`)

- React 19 + Vite 6.
- Tailwind v4 + shadcn/ui.
- TanStack Query v5.
- React Hook Form + Zod.
- React Router v7.

### 2.3 Admin panel (`admin/`)

- Mismo stack que `frontend/`.
- Puerto dev: 5174.
- Proxy `/api` → `http://localhost:3000`.

### 2.4 Go service (`face-search-service/`)

- Go.
- Cloud Run target.
- Integra con Rekognition y PostgreSQL.

---

## 3. Boundaries y dependencias

### 3.1 Capas

A nivel lógico (backend + servicios):

- **Domain**: modelos, reglas de negocio, invariantes.
- **Application**: servicios y casos de uso.
- **Interface**: controllers HTTP / handlers.
- **Infrastructure**: DB, Redis, Rekognition, S3, Twilio, etc.

Regla:
- Interface → Application → Domain.
- Infrastructure depende de Domain/Application, no al revés.

### 3.2 Frontend

- `frontend/` y `admin/` solo hablan con `backend/` (Rails) y, para face search, con Go service.
- No acceden directo a AWS/GCP; todo via APIs backend/Go service.
- State server-side vía TanStack Query, sin inventar client state innecesario.

#### Face search (admin → Go service, bypass Rails)

El panel admin consulta la búsqueda facial **directamente** al Go service, sin pasar por Rails. Esto desacopla la carga de Rekognition del backend principal y evita hop extra.

- Endpoint: `POST {VITE_FACE_SEARCH_URL}/search-face` (default dev: `http://localhost:8081`)
- Auth: header `Authorization: Bearer {VITE_FACE_SEARCH_TOKEN}` (token compartido entre admin y Go service via env vars)
- Request body: `{ "image": "data:image/jpeg;base64,..." }`
- Response: `{ matches: [{ user_id, rut, phone, confidence, face_id }], query_time_ms }`
- CORS: Go service valida origin contra allowlist en `CORS_ORIGINS` (comma-separated). Default dev: `http://localhost:5173,http://localhost:5174`. Sin allowlist = sin CORS = bloqueado por browser.

Regla: el admin NUNCA llama `/api/v1/admin/face-search` en Rails. El endpoint Rails para face records (`GET /api/v1/admin/users/:id/face-records`, `POST .../reindex-face`) es solo para consultar/reindexar caras de un user conocido — no para buscar.

### 3.3 Integraciones externas

- AWS Rekognition + S3.
- GCP: Cloud SQL, Cloud Run, Memorystore.
- Twilio (fase 2).

Todas las integraciones deben pasar por capas de infraestructura dedicadas (no llamadas directas desde dominio).

---

## 4. Diagrama simplificado

```txt
frontend (React)   admin (React)
       │                │
       ├────── API REST ┤
       │                │
        └─── backend (Rails API)
                 │
      ┌──────────┴───────────┐
      │                      │
   PostgreSQL (Cloud SQL)  Redis (Memorystore)
      │
      └── face-search-service (Go, Cloud Run)
               │
           AWS Rekognition + S3
```

---

## 5. Patrones y decisiones arquitectónicas

- Tres frontends separados por responsabilidad (`frontend`, `admin`, `face-search` UI dentro de admin).
- Go service separado del backend Rails para aislar carga y dependencia de Rekognition.
- AWS se usa solo para biometría y fotos; DB principal vive en GCP.
- Face liveness ya existe como Lambda + API Gateway; este proyecto se conecta a su salida, no la implementa.

---

## 6. Escalabilidad y resiliencia (alto nivel)

- Redis para rate limiting y caché.
- Circuit breakers y retry con backoff para:
  - AWS Rekognition
  - S3
  - APIs externas (Twilio, etc).
- Go service stateless en Cloud Run, escalable horizontalmente.
- Health checks para backend y Go service.

---

## 7. Puntos sensibles

- Integración Rekognition (drift de schema en `face_records`).
- Manejo de tokens y cookies entre frontends y backend.
- Sincronización de `SPEC.md` con endpoints reales.
- Consistencia entre IDs de usuario en Rails y Go service.
