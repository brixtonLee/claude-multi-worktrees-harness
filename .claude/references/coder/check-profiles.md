# Coder Self-Check Profiles

Run ONLY the checks matching your **check-profile** (from dispatch prompt). If no profile specified, run all.

## Always (all profiles)

1. [ ] Every acceptance criterion in your prompt has corresponding implementation
2. [ ] All files modified are within WORKTREE_ROOT (if provided)
3. [ ] No files outside the subtask's file list without noting in Unexpected Files
4. [ ] No `.Result` or `.Wait()` — all async chains are properly awaited
5. [ ] Error handling — exceptions not silently swallowed (no empty catch blocks)
6. [ ] Build compiles and tests pass

## Profile: `query`

7. [ ] Domain layer has no `using` references to Infrastructure
8. [ ] Services use interfaces, not concrete implementations
9. [ ] No direct DbContext usage in Application layer

## Profile: `service`

10. [ ] `CancellationToken` passed through async method chains
11. [ ] Service interfaces defined in `Application/Common/Interfaces/`
12. [ ] New classes registered in DI (`DependencyInjection.cs` or equivalent)

## Profile: `endpoint`

13. [ ] Controllers inject services, not Infrastructure directly
14. [ ] Response DTOs, not domain entities, in API responses
15. [ ] Request models have validation

## Profile: `background`

16. [ ] Graceful cancellation via CancellationToken
17. [ ] Scoped service resolution via `IServiceScopeFactory`
18. [ ] Outer try-catch with structured logging

If any check fails and you can fix it within your remaining turns, fix it. If not, report it in your return under Blockers.
