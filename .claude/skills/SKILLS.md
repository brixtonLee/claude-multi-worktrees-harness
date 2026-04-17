# SKILLS — Skill Index

> **Purpose:** Routing table for all C# coding skills.
> Loaded by CODER agent to find relevant patterns. VERIFIER checks compliance against these.

---

## Project Skills

| # | Skill | Description |
|---|-------|-------------|
| 1 | `architecture-layers` | Clean Architecture dependency rules and layer ownership |
| 2 | `entities` | Domain entities, BaseEntity, value objects, enums, domain events |
| 3 | `sealed-records-dtos` | Immutable DTOs using sealed records |
| 4 | `services-interfaces` | Service interfaces, implementations, DI wiring |
| 5 | `ef-core-config` | Fluent API configuration, migrations, RLS |
| 6 | `agent-pipeline` | Orchestrated pipeline pattern, agentic loop, prompt building |
| 7 | `result-error-handling` | Result<T> for expected failures, structured logging |
| 8 | `audit-logging` | Append-only audit trail, JSONB details |
| 9 | `testing` | Unit tests, integration tests, tenant isolation |
| 10 | `async-patterns` | Async-all-the-way, CancellationToken |
| 11 | `file-handling` | Magic bytes detection, file type validation |

## SOLID Skills

| # | Skill | Description |
|---|-------|-------------|
| 12 | `solid-srp` | Single Responsibility Principle |
| 13 | `solid-ocp` | Open/Closed Principle |
| 14 | `solid-lsp` | Liskov Substitution Principle |
| 15 | `solid-isp` | Interface Segregation Principle |
| 16 | `solid-dip` | Dependency Inversion Principle |

## Coder Routing

| Working in... | Auto-loaded skills |
|---------------|-------------------|
| Domain (entities, enums, events) | `architecture-layers` + `entities` |
| Application (agents) | `architecture-layers` + `agent-pipeline` + `result-error-handling` |
| Application (DTOs, mapping) | `architecture-layers` + `sealed-records-dtos` |
| Infrastructure (persistence) | `architecture-layers` + `ef-core-config` |
| Infrastructure (services) | `architecture-layers` + `services-interfaces` |
| Tests | `testing` + the skill for the code under test |
