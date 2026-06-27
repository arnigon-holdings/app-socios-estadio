# Stadium Members App — Architecture

```mermaid
flowchart TB
    subgraph Frontend["Frontend"]
        FE["app_perfil<br/>React SPA"]
        Admin["admin_panel<br/>React SPA"]
    end

    subgraph AWS["AWS Cloud"]
        subgraph Liveness["Rekognition Liveness"]
            Lambda["Lambda<br/>face-liveness-create-session"]
            API["API Gateway"]
            LivenessDetector["FaceLivenessDetector<br/>SDK"]
        end
        subgraph FaceCollection["Rekognition Face Collection"]
            Collection["socios_stadium_users"]
        end
        S3["S3 Bucket<br/>perfilamiento-faces"]
    end

    subgraph GCP["GCP Cloud"]
        subgraph RailsBackend["Rails Backend (Cloud Run)"]
            Rails["Rails 8 API"]
        end
        subgraph GoService["Go Service (Cloud Run)"]
            Go["face-search-service<br/>:8080"]
        end
        PostgreSQL[("Cloud SQL<br/>PostgreSQL")]
        Redis[("Memorystore<br/>Redis")]
    end

    subgraph External["External Systems"]
        Camera["Stadium<br/>Cameras"]
        WhatsApp["WhatsApp<br/>Twilio"]
    end

    %% Frontend to Backend Registration
    FE -->|POST /api/v1/frontend/users<br/>base64 photo + auditImages| Rails
    Rails -->|1. Upload photos| S3
    Rails -->|2. IndexFaces| Collection
    Rails -->|3. Save face_records| PostgreSQL

    %% Liveness Flow
    FE -->|3. POST /face-liveness/sessions| API
    API -->|4. Create Session| Lambda
    FE -->|5. FaceLivenessDetector| LivenessDetector
    LivenessDetector -->|6. WebSocket| Lambda
    FE -->|7. GET /sessions/:id/results| API

    %% Admin Panel
    Admin -->|CRUD users, teams, etc| Rails
    Admin -->|POST /search-face<br/>Bearer token| Go

    %% Camera to Go Service
    Camera -->|Frame with face| Go
    Go -->|SearchFacesByImage| Collection
    Go -->|Query user data| PostgreSQL
    Go -->|matches: rut, phone| Camera

    %% Rails to Redis
    Rails -->|Rate limiting, Cache| Redis

    %% WhatsApp for phone verification (future)
    Rails -->|OTP| WhatsApp

    %% Data stores
    PostgreSQL -->|users, face_records,<br/>teams, audit_logs| Rails
    PostgreSQL -->|users, face_records| Go

    %% Style
    classDef aws fill:#FF9900,color:#000,stroke:#232F3E,stroke-width:2px
    classDef gcp fill:#4285F4,color:#fff,stroke:#4285F4,stroke-width:2px
    classDef frontend fill:#61DAFB,color:#000,stroke:#333,stroke-width:2px
    classDef service fill:#8B5CF6,color:#fff,stroke:#8B5CF6,stroke-width:2px

    class S3,Collection,LivenessDetector,Lambda,API aws
    class PostgreSQL,Redis,RailsBackend,GoService gcp
    class FE,Admin frontend
```

## Main flows

### User registration
```mermaid
sequenceDiagram
    participant FE as Frontend
    participant Lambda as AWS Lambda
    participant API as API Gateway
    participant Rails as Rails Backend
    participant S3 as AWS S3
    participant Rekognition as Rekognition
    participant DB as Cloud SQL

    FE->>Lambda: POST /sessions (create liveness)
    Lambda-->>FE: sessionId

    FE->>FE: FaceLivenessDetector (camera)
    FE->>API: GET /sessions/:id/results
    API->>Lambda: get session results
    Lambda-->>API: { referenceImage, auditImages[] }
    API-->>FE: results

    FE->>Rails: POST /api/v1/frontend/users
    Note over FE,Rails: photo + audit_images base64

    Rails->>S3: PUT users/{id}/reference.jpg
    Rails->>S3: PUT users/{id}/audit_{i}.jpg
    Rails->>Rekognition: IndexFaces (reference)
    Rails->>Rekognition: IndexFaces (audit[])
    Rails->>DB: INSERT user, face_records
    DB-->>Rails: success
    Rails-->>FE: 201 Created
```

### Face search
```mermaid
sequenceDiagram
    participant Camera as Stadium Cameras
    participant Go as Go Service
    participant Rekognition as Rekognition
    participant DB as Cloud SQL

    Camera->>Go: POST /search-face<br/>{ image: base64 }
    Go->>Rekognition: SearchFacesByImage
    Rekognition-->>Go: face_matches[]

    Note over Go: Consolidate by user_id<br/>(multiple faces = same user)

    Go->>DB: SELECT rut, phone<br/>WHERE id = user_id
    DB-->>Go: user data

    Go-->>Camera: [{ rut, phone, confidence }]
```

## Components per cloud

### AWS
| Component | Service | Purpose |
|-----------|----------|-----------|
| S3 Bucket | S3 | Store user photos |
| Face Collection | Rekognition | Face index for search |
| Lambda + API Gateway | Lambda | Face Liveness sessions |
| FaceLivenessDetector | Browser SDK | Liveness challenge UI |

### GCP
| Component | Service | Purpose |
|-----------|----------|-----------|
| Rails Backend | Cloud Run | REST API, business logic |
| Go Service | Cloud Run | Facial search (face search) |
| PostgreSQL | Cloud SQL | Data: users, face_records, teams |
| Redis | Memorystore | Cache, rate limiting |

## Terraform State

| Cloud | State Location |
|-------|---------------|
| AWS | S3 Bucket (`tf-state-aws`) |
| GCP | Cloud Storage (`tf-state-gcp`) |