---
name: solid-isp
description: "Interface Segregation Principle — clients should not be forced to depend on methods they don't use. Use when reviewing fat interfaces, when implementors leave methods as NotImplementedException, or when creating new interfaces."
---

# SOLID: Interface Segregation Principle

## Definition

No client should be forced to depend on methods it doesn't use. Prefer many small, focused interfaces over one large one.

## The Smell

- Interface has 8+ methods and most implementors only use 3-4
- Implementor has methods that throw `NotImplementedException` (also an LSP violation)
- Consumer injects an interface but only calls 1-2 of its 10 methods
- Interface name is vague: `IService`, `IManager`, `IHandler` (hides the fact it does too much)
- Adding a method to the interface forces changes in 5 implementors that don't need it

## The Fix Pattern

Split by consumer need, not by entity:

```csharp
// VIOLATION: fat interface
public interface IAlertEventService
{
    Task<AlertEvent?> GetByIdAsync(Guid tenantId, Guid id);
    Task<PagedList<AlertEvent>> GetPagedAsync(Guid tenantId, AlertEventFilter filter);
    Task ProcessIncomingAsync(AlertEventDto dto, CancellationToken ct);
    Task ReprocessSeverityAsync(Guid tenantId, Guid eventId, CancellationToken ct);
    Task<DailySummaryDto> GetDailySummaryAsync(Guid tenantId, DateTime date, CancellationToken ct);
    Task SendDailySummaryNotificationAsync(Guid tenantId, CancellationToken ct);
    Task ArchiveOldEventsAsync(int daysOld, CancellationToken ct);
}

// FIX: split by consumer
public interface IAlertEventQuery    // API endpoints that read
{
    Task<AlertEvent?> GetByIdAsync(Guid tenantId, Guid id);
    Task<PagedList<AlertEvent>> GetPagedAsync(Guid tenantId, AlertEventFilter filter);
}

public interface IEventProcessing    // Kafka consumers that write
{
    Task ProcessIncomingAsync(AlertEventDto dto, CancellationToken ct);
    Task ReprocessSeverityAsync(Guid tenantId, Guid eventId, CancellationToken ct);
}

public interface IDailySummaryService  // Cron job
{
    Task<DailySummaryDto> GetDailySummaryAsync(Guid tenantId, DateTime date, CancellationToken ct);
    Task SendDailySummaryNotificationAsync(Guid tenantId, CancellationToken ct);
}

public interface IEventArchiver       // Background cleanup job
{
    Task ArchiveOldEventsAsync(int daysOld, CancellationToken ct);
}
```

## Common C# Traps

- **`IRepository<T>` with CRUD + query + aggregate** — split into `IReadRepository<T>` and `IWriteRepository<T>` if some consumers only read.
- **Marker interfaces taken too far** — an interface with 1 method is fine. An interface with 0 methods (`IEntity`) is usually a code smell unless used for generic constraints.
- **Over-segregation** — 15 interfaces with 1 method each, all always used together. If they always change together, they belong together. ISP is about *consumer* needs, not about minimizing method count.

## Interaction with Other Principles

- ISP violations often cause LSP violations (implementor can't fulfill the fat interface)
- ISP + SRP: if a class implements 4 segregated interfaces, it might have too many responsibilities
- ISP enables OCP: small interfaces are easier to add new implementations for

## Examples

Read `${CLAUDE_SKILL_DIR}/references/isp-examples.md` for before/after C# code.
