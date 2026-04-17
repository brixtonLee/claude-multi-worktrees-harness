# Pass 4 — Code Quality

| Check | Criteria | Severity |
|-------|----------|----------|
| Async consistency | No `.Result` or `.Wait()` | Must PASS |
| CancellationToken | Passed through all async chains | Must PASS |
| Error handling | Exceptions not silently swallowed (no empty catch blocks) | Must PASS |
| Resource disposal | `IDisposable`/`IAsyncDisposable` where needed | Must PASS |
| Domain isolation | Domain layer has no Infrastructure references | Must PASS |
| DI usage | Services use interface injection, not concrete types | Must PASS |
| BaseAgent pattern | Agent classes inherit `BaseAgent`, follow existing conventions | Must PASS |
| Edge cases | Null paths, boundary conditions, concurrency | WARN ok |
| Naming/style | Convention consistency | WARN ok |

## Severity Levels

| Severity | Action |
|----------|--------|
| BLOCKER | Must fix — build fails, broken contracts, architectural violations |
| WARNING | Merge + tech-debt entry |
| NOTE | Mention only |
