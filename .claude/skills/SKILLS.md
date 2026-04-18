# SKILLS — Skill Index

> **Purpose:** Routing table for all C# coding skills.
> Loaded by CODER agent to find relevant patterns. VERIFIER checks compliance against these.
>
> **Location:** `.claude/skills/<skill-name>/SKILL.md`

---

## Quick Reference

| Layer / Area             | Auto-load these skills                                              |
|--------------------------|---------------------------------------------------------------------|
| Domain                   | `architecture-layers` · `entities`                                 |
| Application — Agents     | `architecture-layers` · `agent-pipeline` · `result-error-handling` |
| Application — DTOs       | `architecture-layers` · `sealed-records-dtos`                      |
| Infrastructure — Persist | `architecture-layers` · `ef-core-config`                           |
| Infrastructure — Services| `architecture-layers` · `services-interfaces`                      |
| Tests                    | `testing` + skill for the code under test                          |

---

## Project Skills

> Core patterns specific to this codebase. Always check these before writing new code.

| ID | Skill | Layer | Description |
|----|-------|-------|-------------|
| P01 | `architecture-layers` | All | Clean Architecture dependency rules and layer ownership |
| P02 | `entities` | Domain | Domain entities, BaseEntity, value objects, enums, domain events |
| P03 | `sealed-records-dtos` | Application | Immutable DTOs using sealed records |
| P04 | `services-interfaces` | Application / Infra | Service interfaces, implementations, DI wiring |
| P05 | `ef-core-config` | Infrastructure | Fluent API configuration, migrations, RLS |
| P06 | `agent-pipeline` | Application | Orchestrated pipeline pattern, agentic loop, prompt building |
| P07 | `result-error-handling` | Application | Result<T> for expected failures, structured logging |
| P08 | `audit-logging` | Infrastructure | Append-only audit trail, JSONB details |
| P09 | `testing` | Tests | Unit tests, integration tests, tenant isolation |
| P10 | `async-patterns` | All | Async-all-the-way, CancellationToken propagation |
| P11 | `file-handling` | Infrastructure | Magic bytes detection, file type validation |

---

## SOLID Skills

> General OOP design principles. Load when refactoring or designing new abstractions.

| ID | Skill | Principle | When to Load |
|----|-------|-----------|--------------|
| S01 | `solid-srp` | Single Responsibility | Class is doing too many things |
| S02 | `solid-ocp` | Open / Closed | Adding behaviour without modifying existing code |
| S03 | `solid-lsp` | Liskov Substitution | Implementing or extending base types |
| S04 | `solid-isp` | Interface Segregation | Designing or splitting interfaces |
| S05 | `solid-dip` | Dependency Inversion | Wiring dependencies, abstracting Infrastructure |

---

## Coder Routing Detail

Use the table below to decide which skills to load **before writing any code**.  
Only load skills relevant to your current subtask — do NOT read all skills.

```
Working area                  → Skills to load
─────────────────────────────────────────────────────────────────────────────
Domain (entities, enums,      → P01 architecture-layers
  value objects, events)        P02 entities

Application (agents,          → P01 architecture-layers
  agentic loops)                P06 agent-pipeline
                                P07 result-error-handling

Application (DTOs, mapping,   → P01 architecture-layers
  commands, queries)            P03 sealed-records-dtos

Infrastructure (persistence,  → P01 architecture-layers
  EF Core, migrations)          P05 ef-core-config

Infrastructure (services,     → P01 architecture-layers
  external APIs, adapters)      P04 services-interfaces

Tests                         → P09 testing
                                + skill matching the layer under test

Refactor / new abstraction    → S01–S05 as appropriate
─────────────────────────────────────────────────────────────────────────────
```

---

## Notes

- `architecture-layers` (P01) is the **only skill that loads for every subtask** — read it first.
- SOLID skills are **supplemental** — load them during design/refactor, not routine implementation.
- If a pattern you need is not covered by any skill, follow the closest existing pattern in the codebase and flag it in your return under **Notes** so the skill index can be updated.