# Tech Debt & Improvements

> **Purpose:** When agents spot issues outside the current task scope, they go here.
> **During execution:** Write-only. Never read this file during sprint execution.
> **During planning:** ORCHESTRATOR reads this to decide what to tackle next.

---

## Format

```
### [YYYY-MM-DD] [Category] -- [Brief Description]
**File:** [file path]
**Severity:** Low / Medium / High
**Status:** Open | Resolved
**Description:** [What's wrong or could be improved]
**Suggested Fix:** [Optional]
**Spotted During:** [Which task surfaced this]
**Resolved By:** [sprint goal or date — only when Status is Resolved]
```

### Categories
- **CODE** -- code quality, duplication, complexity
- **PERF** -- performance concerns
- **SEC** -- security issues
- **TEST** -- missing or weak test coverage
- **ARCH** -- architectural concerns
- **DEPS** -- dependency issues

---

## Items

<!-- Append new items below. -->

### [2026-04-08] CODE -- Inconsistent fallback field in keyed DI factories
**File:** VSH.AlertCollectorAPI.Infrastructure/StartUp/DependencyInjection.cs
**Severity:** Low
**Status:** Open
**Description:** Keyed ILarkAuth("Duplicate") checks `AppId` for fallback, while keyed ILarkNotification("Duplicate") checks `GroupId`. In practice both will be empty/populated together, but the inconsistency could confuse future readers.
**Suggested Fix:** Unify to check a single field (e.g., `AppId`) for both, or document the intentional divergence with a comment.
**Spotted During:** Refactor Duplicate Lark Bot Config to Separate Sections
