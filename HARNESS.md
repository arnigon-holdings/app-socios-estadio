# HARNESS.md — Marco de Harness Engineering

## Objetivo
Este archivo documenta cómo gobernamos el trabajo del agente en este proyecto.
No define detalle funcional del producto.
Define principios de control: guías antes de actuar y sensores después de actuar.

## Referencias principales
- Martin Fowler — Harness Engineering for Coding Agent Users
- Martin Fowler — Maintainability Sensors for Coding Agents

## Idea central
Un agente no es solo modelo.
Agente = modelo + harness.

El harness es conjunto de:
- contexto
- instrucciones
- restricciones
- herramientas
- sensores
- loops de verificación

Objetivo:
- aumentar acierto antes de actuar
- detectar errores rápido después de actuar
- permitir auto-corrección
- reducir retrabajo humano

## Feedforward y feedback
### Feedforward
Guías antes de actuar.
Ejemplos:
- `AGENTS.md`
- `SPEC.md`
- `ARCHITECTURE.md`
- convenciones del repo
- templates
- comandos estándar
- boundaries

Objetivo:
- reducir espacio de soluciones
- empujar al agente hacia caminos correctos

### Feedback
Sensores después de actuar.
Ejemplos:
- formatter
- linter
- typecheck
- tests
- build
- code review
- checks de arquitectura
- observabilidad en entornos reales

Objetivo:
- detectar desviaciones
- permitir auto-corrección
- aumentar confianza

## Regla clave
Feedforward sin feedback = agente no sabe si funcionó.
Feedback sin feedforward = agente itera caro y repite errores.

Se necesitan ambos.

## Tipos de sensores
### Sensores computacionales
Baratos, rápidos, deterministas.
Ejemplos:
- lint
- format
- typecheck
- unit tests
- integration tests
- build
- scans de seguridad
- checks de contratos
- checks de imports y dependencias

Regla:
- correr en cada cambio relevante
- preferir primero estos

### Sensores inferenciales
Más caros, más lentos, menos deterministas.
Ejemplos:
- AI review
- análisis de mantenibilidad asistido por LLM
- mutation testing guiado
- evaluaciones amplias de arquitectura

Regla:
- usar post-integración o en tareas de mayor riesgo
- no reemplazan sensores computacionales

## Categorías de regulación
### 1. Maintainability
Controla:
- complejidad
- duplicación
- drift de estilo
- claridad estructural
- deuda técnica visible

### 2. Architecture fitness
Controla:
- boundaries
- performance crítica
- resiliencia
- logging
- observabilidad
- topología correcta entre capas y servicios

### 3. Behaviour
Controla:
- que sistema haga lo correcto según spec
- tests de comportamiento
- contratos
- flujos críticos del negocio

Es categoría más difícil.
No depende solo de lint o style.

## Loop de trabajo
Human steers -> Agent acts -> Sensors detect -> Agent self-corrects -> Human reviews

Regla:
- si un problema ocurre 3 o más veces, agregar nueva guía o nuevo sensor

## Prioridades de decisión
Antes de agregar código, verificar en este orden:
1. Calidad
2. Eficiencia
3. Seguridad
4. Añadir código nuevo

Interpretación:
- si se puede resolver borrando, simplificando o reutilizando, preferir eso
- agregar código es último recurso, no primero

## No orphan code
- Código nuevo debe quedar conectado a feature, flujo o módulo real
- Código sin uso debe eliminarse
- Imports sin usar deben limpiarse
- Helpers sin adopción real deben evitarse
- Test inexistente o imposible de verificar debe dejar nota explícita

## Niveles de riesgo
### Read-only
- Solo lectura
- Puede operar sin confirmación

### Draft
- Simulación o propuesta
- Sin side effects externos
- Preferir este modo si hay duda

### External write
- DB
- filesystem importante
- APIs externas
- infraestructura
- cambios irreversibles o costosos

Requiere aprobación humana antes de ejecutar parte sensible.

## Budgets
- step_budget: 50 iteraciones máximo por tarea
- time_budget: 5 minutos antes de pedir input si hay bloqueo o ambigüedad
- token_budget: usar contexto con disciplina, priorizando instrucciones y archivos relevantes
- cost_budget: definir por proyecto si hay herramientas externas pagadas

## Context layering
Ordenar contexto de más estable a más volátil:
1. system policies
2. reglas del agente
3. instrucciones del proyecto
4. contexto de sesión
5. resultados JIT de herramientas

Regla:
- contexto estable arriba
- contexto dinámico abajo
- no inflar prompt principal con documentación larga si puede ir en archivos consultables

## Ashby
Un regulador debe tener al menos tanta variedad como el sistema que regula.

Implicación práctica:
- usar templates y topologías predefinidas
- reducir caminos posibles
- hacer explícito lo que hoy vive solo en cabeza de seniors
- especializar agentes por tarea cuando el sistema crece

## Aplicación en este repo
Este archivo no reemplaza `AGENTS.md`.

Usar:
- `AGENTS.md` para reglas operativas
- `SPEC.md` para verdad funcional
- `ARCHITECTURE.md` para boundaries
- `INFRASTRUCTURE.md` para cloud e IaC

Cuando una falla se repita:
1. decidir si faltó guía o faltó sensor
2. corregir documento correcto
3. agregar validación si corresponde
