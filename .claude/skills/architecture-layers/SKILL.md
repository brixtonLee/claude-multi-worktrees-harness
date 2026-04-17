---
name: architecture-layers
description: "Clean Architecture dependency rules and layer ownership. Use when working on any layer boundary, creating new files, or reviewing imports/references."
context:
  - .claude/skills/solid-dip/SKILL.md
---

# Skill: Architecture Layers

## Dependency Direction (Inward Only)

```
Domain ← Application ← Infrastructure ← API / Dashboard
```

| Layer | Can Reference | Cannot Reference |
|-------|--------------|-----------------|
| Domain | Nothing (zero deps) | Application, Infrastructure, API |
| Application | Domain | Infrastructure, API |
| Infrastructure | Domain, Application | API |
| API / Dashboard | All layers | — |

## Hard Rules

- Domain has ZERO external dependencies (no EF Core, no Newtonsoft, nothing)
- Application depends only on Domain
- Infrastructure implements interfaces defined in Application/Domain
- API/Dashboard depend on everything via DI registration
- **NEVER** reference Infrastructure from Domain or Application directly
- **NEVER** put business logic in controllers or Blazor pages
- **NEVER** reference `DbContext` from Application layer — use `IAppDbContext` interface

## What Lives Where

| Item | Layer |
|------|-------|
| Entities, Value Objects, Enums, Domain Events | Domain |
| Marker Interfaces (IAuditable, ITenantEntity) | Domain |
| Agent Logic, DTOs/Models, Validators, Guards | Application |
| Service/Data Interfaces (IAppDbContext, ILlmProvider, etc.) | Application |
| EF Core DbContext, Service Implementations | Infrastructure |
| LLM Clients, External API Clients, Quartz Jobs | Infrastructure |
| Controllers, Middleware | API |
| Blazor Pages | Dashboard |

## Verification

```bash
grep -rn "using AiAgents.Infrastructure" src/AiAgents.Domain/ src/AiAgents.Application/
grep -rn "DbContext\|AppDbContext" src/AiAgents.Application/
grep -rn "HttpClient" src/AiAgents.Domain/
```

All must return ZERO results.
