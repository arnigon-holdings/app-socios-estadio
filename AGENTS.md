# AGENTS.md — Stadium Members App

## Purpose

SaaS platform for member registration with facial verification and a points system.

## Stack

- Frontend: React 19 + Vite + Tailwind v4 + shadcn/ui
- Backend: Rails 8 API
- Biometric service: Go service on Cloud Run
- AWS: Rekognition, S3
- GCP: Cloud SQL PostgreSQL, Cloud Run, Memorystore Redis

## Setup (for agents / LLMs landing on the project)

The project is split across **6 git repos** (this root infra repo + 4 app polyrepos + 1 docs repo). Clone them all before doing any work so that cross-repo references resolve and polyrepo code is available locally:

```bash
# from a parent directory
git clone https://github.com/arnigon-holdings/app-socios-estadio-infra.git
cd app-socios-estadio-infra

# app polyrepos (each is an independent git repo with its own .git)
git clone https://github.com/arnigon-holdings/app-socios-estadio-backend.git     backend
git clone https://github.com/arnigon-holdings/app-socios-estadio-frontend.git    frontend
git clone https://github.com/arnigon-holdings/app-socios-estadio-admin.git       admin
git clone https://github.com/arnigon-holdings/app-socios-estadio-face-search.git face-search-service

# docs repo (optional — full AGENTS.md, SPEC.md, ARCHITECTURE.md, INFRASTRUCTURE.md, Makefile)
git clone https://github.com/arnigon-holdings/app-socios-estadio-docs.git        docs-repo
```

After cloning, follow the quickstart in [`README.md`](./README.md) for prereqs (Docker, Node 20+, Ruby 3.4, AWS CLI) and dev commands per subsystem. For the full repo map and what each polyrepo contains, see "Project repo map" in [`README.md`](./README.md).

For architecture context (components per cloud, main flows), read [`docs/ARQUITECTURA.md`](./docs/ARQUITECTURA.md). For Terraform organization, read [`infrastructure/README.md`](./infrastructure/README.md).

## Main Rule

This file defines how the agent must work on this project.
Priority: quality, accuracy, security, small changes, low rework.

## Communication

- In chat with humans: use caveman full.
- When writing code: do NOT use caveman in code, names, comments, tests, commits, or PRs.
- Code is always normal, readable, and maintainable.
- Comments only when they explain the why, not the obvious.

## Mandatory Workflow

Before changing code:
1. Summarize the objective.
2. State assumptions and constraints.
3. Identify affected files, modules, and layers.
4. Propose a minimal plan.
5. Define completion criteria.

During implementation:
- Make small, local, reversible changes.
- Touch only the files that are necessary.
- Follow existing patterns before creating new ones.
- If a change grows, split it into steps.
- No broad refactors unless explicitly instructed.

After implementation:
- Run the project's validations.
- Report what was verified and what was not.
- Do not declare "done" without clarifying verification limits.

## Harness Engineering

Apply guides before acting and sensors after acting.

### Guides

- Follow the repo's architecture, conventions, and boundaries.
- Reuse existing code before creating new code.
- Remove dead code related to the change.
- Keep diffs easy to review.
- Favor simple and maintainable solutions.

### Sensors

After relevant changes, run as applicable:
- `make validate` (markdown lint + link check, in the docs repo)
- `make lint`, `make links` (in the docs repo)

> **This repo (root infra)**: does not have its own `Makefile`. Docs validation lives in [`app-socios-estadio-docs`](https://github.com/arnigon-holdings/app-socios-estadio-docs) (where `make validate` runs).
>
> **Each polyrepo subsystem**: run that subsystem's `Makefile` (it has stack-specific targets).

If additional checks exist per stack, use them too:
- Frontend: component tests, typecheck, build
- Rails: tests, linters, schema validations
- Go: tests, format, vet or lint
- Terraform: `terraform validate` + `terraform plan`

If something fails, fix it before continuing or report the blocker explicitly.

## Implementation Principles

Order of priority:
1. Quality
2. Efficiency
3. Security
4. Adding new code

Rules:
- KISS first.
- DRY only when there is real duplication.
- Delete obsolete code; do not comment it out.
- Do not leave unused imports.
- Do not create new helpers, services, or hooks if an equivalent already exists.
- Do not abstract prematurely.
- Every new abstraction must answer a real current need.
- Keep functions and components with clear responsibility.
- Avoid unnecessary coupling between frontend, backend, and the Go service.

### UX Rule: Hide the Technology Layer

- No user-facing text (admin, member, or any role) may mention providers or infrastructure services: AWS, GCP, Azure, Rekognition, S3, Cloud SQL, Lambda, Cloud Run, etc.
- Technical references live only in variable names, type fields, code comments, internal `*.md`, and file/resource names. End users never see "Rekognition", "AWS", "GCP", etc. in the UI.
- When adding error or loading messages, describe the behavior ("Verifying your identity", "Searching matches", "No faces registered") without appealing to the brand or service behind it.
- Allowed exception: fields like `rekognition_face_id` in types/API contracts are internal contract names and are not shown to the user.

## Architecture and Boundaries

### Frontend

- UI components separated from business logic.
- Avoid complex logic inside components if it can live in hooks, services, or dedicated layers.
- Reuse shadcn/ui components and existing patterns before creating new variants.
- Avoid global state if local or server state is sufficient.

### Rails Backend

- Keep controllers thin.
- Move business logic to services, models, or layers already defined by the project.
- Validate inputs at the entry boundaries.
- Avoid N+1 queries.
- Be explicit with transactions when the flow requires them.
- Structured logs, useful and without secrets.

### Go Service

- Small, explicit, predictable APIs.
- Mandatory timeouts on external calls.
- Clear error handling.
- Mandatory health checks.
- Prepared for circuit breaker, retry with backoff, and graceful degradation when applicable.

## Infrastructure

- All new or modified infrastructure must go through Terraform.
- Do not make manual changes as a final solution.
- Separate Terraform by domain following the project structure.
- Do not hardcode resource names, secrets, URLs, or credentials.
- All variable configuration must go through variables or environment variables.
- Keep `.env.example` updated if required configuration changes.

## Security

- Never hardcode credentials, API keys, tokens, or secrets.
- Do not expose sensitive data in logs.
- Validate inputs and permissions.
- Treat external operations and side effects as a major risk.
- If a task involves external writes, follow the corresponding risk level.

## Operational Risk

### Read-only

- Read only.
- Can proceed without confirmation.

### Draft

- Simulation or proposal without external side effects.
- Prefer this mode if in doubt.

### External Write

- Changes with external effects: DB, APIs, important filesystem, infrastructure.
- Requires explicit approval before executing sensitive actions.

## Scalability and Resilience

When the change justifies it, consider:
- Cache with Redis
- Retry with backoff
- Circuit breaker
- Queues for heavy or async work
- Graceful degradation
- Health checks
- Timeouts on every external call

Do not apply complex patterns by default if the current problem does not need them.

## Project Commands

Use these commands before closing work, according to the subsystem:

**Docs repo** ([`app-socios-estadio-docs`](https://github.com/arnigon-holdings/app-socios-estadio-docs)):
- `make validate` — markdown lint + link check
- `make lint` / `make links` (granular)

**Each polyrepo subsystem** has its own `Makefile` with stack-specific targets:
- frontend: `make dev` / `make build` / `make lint` / `make validate`
- admin: same as frontend
- backend: `make lint` (rubocop) / `make test` (rails) / `make db_seed` / `make db_console` / `make logs`
- face-search-service: Go targets (`go build` / `go test` / `go vet`)

If a target is missing or does not exist, report it and propose an adjustment to that subsystem's `Makefile`.

## Definition of Done

A change is ready only if:
- It meets the requested objective.
- It respects architecture and boundaries.
- It does not introduce obvious duplication or new dead code.
- It passes relevant validations or clearly reports what could not be verified.
- It considers security and configuration.
- It updates tests or minimal docs when applicable.

## Work Budget

- Step budget: maximum 50 iterations per task.
- Time budget: maximum 5 minutes without requesting input if there is uncertainty or a blocker.
- If context, risk, or scope grows too much, stop and summarize the state.

## Expected Agent Output

Always respond with:
- Objective
- Plan
- Changes
- Verification
- Risks or pending items

## Reference Files

> **Note**: this AGENTS.md is the short version that lives at the root. The full version + detailed docs live in the [`app-socios-estadio-docs`](https://github.com/arnigon-holdings/app-socios-estadio-docs) repo. As of this change, the root does NOT contain more docs (SPEC, ARCHITECTURE, INFRASTRUCTURE, etc.) — all of them are in that repo.

### Internal (this repo)

| File | Purpose |
|---|---|
| [`README.md`](./README.md) | Project entry point — stack, quickstart, conventions, polyrepo map |
| [`docs/ARQUITECTURA.md`](./docs/ARQUITECTURA.md) | Architecture diagrams and main flows (user registration, face search) |
| [`infrastructure/README.md`](./infrastructure/README.md) | Terraform infrastructure overview |
| [`infrastructure/frontend-liveness/README.md`](./infrastructure/frontend-liveness/README.md) | Face Liveness Terraform module detail |

### External (docs repo)

- [`app-socios-estadio-docs/AGENTS.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/AGENTS.md): full version of this file (operational rules)
- [`app-socios-estadio-docs/SPEC.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/SPEC.md): functional source of truth
- [`app-socios-estadio-docs/ARCHITECTURE.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/ARCHITECTURE.md): architecture decisions
- [`app-socios-estadio-docs/INFRASTRUCTURE.md`](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/INFRASTRUCTURE.md): cloud and Terraform detail
- `Makefile` (in docs repo): common validation targets