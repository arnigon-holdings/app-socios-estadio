# SPEC.md — App Socios Estadio

## 1. Overview

**Nombre**: App Socios Estadio  
**Tipo**: Plataforma SaaS multi-tenant para gestión de socios de equipos de fútbol chilenos.  
**Propósito**: Registro de usuarios con verificación de identidad (RUT + foto + teléfono), sistema de puntos gamificado, panel de administración, y búsqueda biométrica facial.  

### 1.1 Objetivos
- Identificar y verificar hinchas y socios de equipos de fútbol chilenos.
- Generar engagement mediante puntos, acciones y logros.
- Preparar plataforma para monetización futura vía beneficios y marketplace.

### 1.2 No objetivos (por ahora)
- No es una ticketera ni sistema de acceso físico a estadio.
- No es un CRM completo de clubes.
- No es red social ni sistema de mensajería entre usuarios.
- No maneja pagos dentro de esta fase.

---

## 2. Usuarios y casos de uso

### 2.1 Usuarios

- **Hincha**:
  - Se registra con RUT, teléfono, contraseña y foto.
  - Verifica teléfono.
  - Elige equipos favoritos.
  - Acumula puntos por acciones.

- **Admin de club/plataforma**:
  - Gestiona usuarios, equipos y reglas de puntos.
  - Revisa ledger de puntos.
  - Audita cambios.

### 2.2 Casos de uso principales

1. **Registro de usuario**:
   - El hincha completa wizard de 7 pasos.
   - Sube foto y pasa liveness.
   - Al verificar teléfono, recibe puntos de registro.

2. **Login**:
   - Se autentica con RUT + password.
   - Accede a dashboard con balance de puntos y últimas transacciones.

3. **Selección de equipos**:
   - Marca 0–5 equipos favoritos.
   - Recibe puntos por selección de equipos válidos.

4. **Gestión admin**:
   - Admin lista usuarios, filtra por RUT.
   - Edita datos clave (teléfono, equipos, estado).
   - Gestiona equipos, point actions, ledger y audit logs.

5. **Búsqueda por cara (M5)**:
   - Admin captura o sube foto.
   - Go service busca cara en Rekognition.
   - Devuelve posibles matches con confianza, RUT y teléfono.

---

## 3. Invariantes del dominio

- Un RUT solo puede pertenecer a un usuario.
- Un usuario solo recibe puntos de `registration` cuando su teléfono está verificado.
- Un usuario puede tener entre 0 y 5 equipos activos.
- Toda imagen indexada en Rekognition debe tener registro correspondiente en `face_records`.
- Toda mutación de admin debe generar un `AuditLog`.
- Un `PointTransaction` siempre referencia un `PointAction` existente.
- No puede haber dos `PointAction` con mismo `action_key`.

---

## 4. Modelo de datos (vista funcional)

### 4.1 Entidades clave (resumen)

- **User**
  - Campos principales: `rut`, `phone`, `password_digest`, `photo_url`, `teams_ids`, `consents`, `phone_verified`, `referral_code`, `referred_by`, `indexed_at`.
  - Guarde metadata básica (device, IP, etc).

- **FaceRecord**
  - `user_id`, `rekognition_face_id`, `face_type` (`reference` | `audit`), `s3_key`, `confidence`.

- **Team**
  - `name`, `short_name`, `logo_url`, `active`.

- **PointAction**
  - `action_key`, `description`, `points`, `active`.

- **PointTransaction**
  - `user_id`, `point_action_id`, `amount`, `reference_id`, `metadata`.

- **Admin**
  - `email`, `password_digest`, `role`.

- **AuditLog**
  - `admin_id`, `action`, `resource_type`, `resource_id`, `metadata`, `ip`.

### 4.2 Índices funcionalmente importantes

- `users.rut` → UNIQUE.
- `users.referral_code` → UNIQUE.
- `teams.name`, `teams.short_name` → UNIQUE.
- `point_actions.action_key` → UNIQUE.
- `face_records.user_id`, `face_records.rekognition_face_id` → índices para búsquedas.
- Índices para queries frecuentes de auditoría y ledger (por admin, por resource, por user).

---

## 5. API (contratos funcionales)

### 5.1 Registro usuario

`POST /api/v1/frontend/users`

- Body (resumen):
  - `rut`, `phone`, `password`, `birth_month`, `birth_year`
  - `photo` (base64)
  - `audit_images[]` (base64[])
  - `teams_ids[]`
  - `consents` (los 3 flags en true)

- Comportamiento:
  - Valida RUT, teléfono, foto y consentimientos.
  - Crea usuario en DB.
  - Sube foto y audit images a storage.
  - Indexa caras en Rekognition.
  - Crea registros en `face_records`.
  - Estado final: usuario creado, `phone_verified = false`, sin puntos de registro aún.

- Respuesta (éxito):
  - `user` (datos básicos)
  - `referral_code`.

- Errores:
  - `422` validación.
  - `409` RUT duplicado.
  - `429` rate limit.

### 5.2 Auth usuario

- `POST /api/v1/login`:
  - Body: `rut`, `password`.
  - Efecto: setea cookies httpOnly de access/refresh.
  - Errores: `401` credenciales, `403` si está bloqueado, `429` rate limit.

- `DELETE /api/v1/logout`:
  - Limpia cookies, revoca refresh token.

- `POST /api/v1/refresh`:
  - Genera nuevo access token a partir de refresh válido.

- `GET /api/v1/me`:
  - Devuelve `user`, `points_balance`, `recent_transactions[]`.

### 5.3 Verificación teléfono

`POST /api/v1/verify-phone`

- Body: `{ token }`.
- Behaviour:
  - Marca `phone_verified = true` si token válido.
  - Dispara `PointTransaction` de `registration` y/o `phone_verification` según config actual.
- Respuesta:
  - `{ verified: true, points_awarded: integer }`.

### 5.4 API Admin (high‑level)

- Auth admin vía `POST /api/v1/admin/login`.
- Dashboard: `GET /api/v1/admin/dashboard` con KPIs.
- Users CRUD + face records + reindex: endpoints `admin/users`.
- Teams CRUD: `admin/teams`.
- Point actions CRUD: `admin/point_actions`.
- Point transactions: `admin/point_transactions`.
- Audit logs: `admin/audit_logs`.
- Face search endpoint en panel admin (usa Go service): `/face-search` vía frontend.

---

## 6. Validaciones de negocio

### 6.1 RUT chileno

- Formato de entrada: `12345678-9` o `12.345.678-K`.
- Normalización: guardar sin puntos ni guión, DV en mayúscula (`K` válido).
- Validación: algoritmo módulo 11.
- Mensaje de error: `"RUT inválido"`.

### 6.2 Teléfono

- Input: 8 dígitos locales (`9XXXXXXXX`).
- Normalización: se guarda como `+569XXXXXXXX`.
- En Fase 2 se valida vía WhatsApp (Twilio).

### 6.3 Foto

- JPEG/PNG, max 5MB, mínimo 200x200.
- Validar por MIME real, no solo extensión.
- Liveness + audit images deben ser indexables por Rekognition.

### 6.4 Password

- Min 8 caracteres.
- Hash bcrypt.
- No se loguea en texto plano.

### 6.5 Equipos

- 0 a 5 equipos.
- Todos deben existir y estar activos.
- Puntos por selección config vía `PointAction.team_selection`.

### 6.6 Consentimientos

- `lgpd`, `terms`, `photo_usage` deben ser `true`.
- Sin los 3 checkboxes en true, registro no avanza.

---

## 7. Sistema de puntos

### 7.1 PointActions (ejemplo inicial)

| key | descripción | puntos | fase |
|-----|-------------|--------|------|
| registration | Registro completado + teléfono verificado | 500 | 1 |
| phone_verification | Verificación phone (si se separa) | 100 | 1 |
| team_selection | Por equipo seleccionado | 50 | 1 |
| referral | Por referido que se registra | 200 | 2 |

(Futuras acciones para fases 2–3 se configuran vía admin, no hardcode.)

### 7.2 Reglas

- `registration` se acredita solo cuando `phone_verified = true`.
- `team_selection`: se acredita al guardar equipos; máximo 5 equipos.
- `referral`: solo cuando referido completa registro válido.
- `points_balance` = suma de `PointTransaction.amount` para el usuario.

---

## 8. Flujos clave

### 8.1 Registro (happy path)

1. Usuario entra a `/registro`.
2. Completa RUT válido.
3. Ingresa teléfono válido.
4. Crea password.
5. Completa liveness (foto + audit images).
6. Elige equipos (opcional).
7. Acepta consentimientos.
8. Envía formulario.
9. Backend crea usuario, guarda metadata y dispara indexación facial.
10. UI muestra pantalla de éxito con instrucción de verificar WhatsApp.

### 8.2 Búsqueda por cara (admin)

1. Admin va a `/face-search`.
2. Sube foto o captura frame.
3. Frontend envía imagen al Go service con token.
4. Go service llama `SearchFacesByImage` (umbral 96%).
5. Consolida matches por `user_id` y devuelve matches.
6. UI muestra lista de posibles usuarios, confianza y link a detalle.

---

## 9. Acceptance criteria (ejemplos)

### 9.1 Registro y puntos

- Dado un usuario nuevo con RUT válido y datos correctos:  
  Cuando completa wizard y verifica teléfono, entonces:
  - `phone_verified = true`.
  - Tiene al menos un `PointTransaction` de tipo `registration`.
  - `points_balance >= registration_points`.

### 9.2 Face search

- Dado un usuario con `FaceRecord` indexado:  
  Cuando admin sube foto del rostro suficientemente similar, entonces:
  - Go service devuelve `matches` no vacío.
  - Primer match tiene `user_id` correcto y `confidence >= 96`.

---

## 10. Pendientes de producto (alto nivel)

- Verificación real WhatsApp (Twilio).
- Sistema de referrals completo.
- Eventos, encuestas, predicciones, marketplace (fases 3+).
- i18n y dark mode en frontends.
