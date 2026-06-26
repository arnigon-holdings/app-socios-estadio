# AGENTS.md — App Socios Estadio

## Propósito
Plataforma SaaS para registro de socios con verificación facial y sistema de puntos.

## Stack
- Frontend: React 19 + Vite + Tailwind v4 + shadcn/ui
- Backend: Rails 8 API
- Servicio biométrico: Go service en Cloud Run
- AWS: Rekognition, S3
- GCP: Cloud SQL PostgreSQL, Cloud Run, Memorystore Redis

## Regla principal
Este archivo define cómo debe trabajar el agente en este proyecto.
Prioridad: calidad, precisión, seguridad, cambios pequeños, bajo retrabajo.

## Comunicación
- En chat con humano: usar caveman full.
- Al programar: NO usar caveman en código, nombres, comentarios, tests, commits o PRs.
- Código siempre normal, legible y mantenible.
- Comentarios solo cuando expliquen el porqué, no lo obvio.

## Flujo obligatorio de trabajo
Antes de cambiar código:
1. Resumir objetivo.
2. Declarar supuestos y restricciones.
3. Identificar archivos, módulos y capas afectadas.
4. Proponer plan mínimo.
5. Definir criterio de término.

Durante implementación:
- Hacer cambios pequeños, locales y reversibles.
- Tocar solo archivos necesarios.
- Seguir patrones existentes antes de crear nuevos.
- Si el cambio crece, dividir en pasos.
- No hacer refactor amplio salvo instrucción explícita.

Después de implementar:
- Ejecutar validaciones del proyecto.
- Reportar qué se verificó y qué no.
- No declarar “listo” sin aclarar límites de verificación.

## Harness engineering
Aplicar guías antes de actuar y sensores después de actuar.

### Guías
- Seguir arquitectura, convenciones y boundaries del repo.
- Reutilizar código antes de crear código nuevo.
- Eliminar código muerto relacionado con el cambio.
- Mantener diffs fáciles de revisar.
- Favorecer soluciones simples y mantenibles.

### Sensores
Después de cambios relevantes, ejecutar según aplique:
- `make fmt`
- `make lint`
- `make test`
- `make validate`

Si existe chequeo adicional por stack, usarlo también:
- Frontend: tests de componentes, typecheck, build
- Rails: tests, linters, validaciones de schema
- Go: tests, format, vet o lint

Si algo falla, corregir antes de seguir o reportar bloqueo explícitamente.

## Principios de implementación
Orden de prioridad:
1. Calidad
2. Eficiencia
3. Seguridad
4. Agregar código nuevo

Reglas:
- KISS primero.
- DRY solo cuando haya duplicación real.
- Borrar código obsoleto, no comentarlo.
- No dejar imports sin uso.
- No crear helpers, services o hooks nuevos si ya existe uno equivalente.
- No abstraer por anticipación.
- Toda nueva abstracción debe responder a una necesidad real actual.
- Mantener funciones y componentes con responsabilidad clara.
- Evitar acoplamiento innecesario entre frontend, backend y servicio Go.

### Regla de UX: ocultar la capa tecnológica
- Ningún texto visible al usuario (admin, socio, o cualquier rol) puede mencionar proveedores ni servicios de infraestructura: AWS, GCP, Azure, Rekognition, S3, Cloud SQL, Lambda, Cloud Run, etc.
- Las referencias técnicas viven solo en nombres de variables, type fields, comentarios de código, `*.md` interno y nombres de archivo/recursos. El usuario final nunca ve "Rekognition", "AWS", "GCP", etc. en la UI.
- Al agregar mensajes de error o loading, describir el comportamiento ("Verificando tu identidad", "Buscando coincidencias", "Sin caras registradas") sin apelar a la marca o servicio detrás.
- Excepción permitida: el campo `rekognition_face_id` y similares en types/API contracts son nombres internos del contrato, no se muestran al usuario.

## Arquitectura y boundaries
### Frontend
- Componentes de UI separados de lógica de negocio.
- Evitar lógica compleja dentro de componentes si puede vivir en hooks, servicios o capas dedicadas.
- Reusar componentes de shadcn/ui y patrones existentes antes de crear variantes nuevas.
- Evitar estado global si estado local o server state es suficiente.

### Backend Rails
- Mantener controllers delgados.
- Mover lógica de negocio a servicios, models o capas ya definidas por el proyecto.
- Validar inputs en bordes de entrada.
- Evitar queries N+1.
- Ser explícito con transacciones cuando el flujo lo requiera.
- Logs estructurados, útiles y sin secretos.

### Go service
- APIs pequeñas, explícitas y predecibles.
- Timeouts obligatorios en llamadas externas.
- Manejo de errores claro.
- Health checks obligatorios.
- Preparado para circuit breaker, retry con backoff y graceful degradation cuando aplique.

## Infraestructura
- Toda infraestructura nueva o modificada debe ir por Terraform.
- No hacer cambios manuales como solución final.
- Separar Terraform por cloud según estructura del proyecto.
- No hardcodear nombres de recursos, secretos, URLs o credenciales.
- Toda configuración variable debe ir por variables o environment variables.
- Mantener `.env.example` actualizado si cambia configuración requerida.

## Seguridad
- Nunca hardcodear credentials, API keys, tokens o secrets.
- No exponer datos sensibles en logs.
- Validar inputs y permisos.
- Tratar operaciones externas y side effects como riesgo mayor.
- Si una tarea implica escritura externa, seguir nivel de riesgo correspondiente.

## Riesgo operativo
### Read-only
- Solo lectura.
- Se puede avanzar sin confirmación.

### Draft
- Simulación o propuesta sin side effects externos.
- Preferir este modo si hay duda.

### External write
- Cambios con efectos externos: DB, APIs, filesystem importante, infraestructura.
- Requiere aprobación explícita antes de ejecutar acciones sensibles.

## Escalabilidad y resiliencia
Cuando el cambio lo justifique, considerar:
- Cache con Redis
- Retry con backoff
- Circuit breaker
- Colas para trabajo pesado o async
- Graceful degradation
- Health checks
- Timeouts en toda llamada externa

No aplicar patrones complejos por defecto si el problema actual no lo necesita.

## Comandos del proyecto
Usar estos comandos antes de cerrar trabajo:
- `make deps`
- `make fmt`
- `make lint`
- `make test`
- `make validate`

Si falta alguno o no existe, reportarlo y proponer ajuste al Makefile.

## Definition of Done
Un cambio está listo solo si:
- Cumple objetivo solicitado.
- Respeta arquitectura y boundaries.
- No introduce duplicación obvia ni código muerto nuevo.
- Pasa validaciones relevantes o se reporta claramente qué faltó verificar.
- Considera seguridad y configuración.
- Actualiza tests o docs mínimas si corresponde.

## Presupuesto de trabajo
- Step budget: máximo 50 iteraciones por tarea.
- Time budget: máximo 5 minutos sin pedir input si hay incertidumbre o bloqueo.
- Si contexto, riesgo o alcance crece demasiado, parar y resumir estado.

## Salida esperada del agente
Siempre responder con:
- Objetivo
- Plan
- Cambios
- Verificación
- Riesgos o pendientes

## Archivos de referencia
- `SPEC.md`: fuente de verdad funcional
- `ARCHITECTURE.md`: decisiones de arquitectura
- `INFRASTRUCTURE.md`: detalle cloud y Terraform
- `README.md`: setup y comandos
