---
name: testing
description: "Unit tests, integration tests, tenant isolation, naming conventions. Use when writing or reviewing tests."
context:
  - .claude/skills/solid-dip/SKILL.md
---

# Skill: Testing

## Naming: `{Method}_{Scenario}_{Expected}`

```csharp
[Fact]
public void Enforce_HighAmount_FlagsForReview() { /* ... */ }
```

## What to Test

| Area | Required Tests |
|------|---------------|
| SoulGuard | Every SOUL.md rule |
| Agent pipelines | Happy path, budget exceeded, duplicate, Claude error |
| Repositories | Tenant isolation (cross-tenant rejection), paging, filtering |
| Entities | Domain method validation, domain event raising |
| Value Objects | Construction validation (e.g., negative Money) |

## Rules

- Test error paths, not just happy path
- Agent pipelines: always test budget exceeded scenario
- SOUL.md rules: every rule has a corresponding test
- Tenant isolation: every repository needs a cross-tenant rejection test
- Use factory helpers (`CreateInvoice`, `CreateContext`)
- No mocking DB in integration tests — hit real PostgreSQL
- Test class: `{ClassUnderTest}Tests`, project: `AiAgents.{Layer}.Tests`

## Location

```
tests/AiAgents.Domain.Tests/           tests/AiAgents.Application.Tests/
tests/AiAgents.Infrastructure.Tests/
```
