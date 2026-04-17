# ISP — Before/After Examples

## Before: Fat Notification Interface

```csharp
public interface ILarkNotification
{
    Task SendFiringNotificationAsync(AlertEvent evt, CancellationToken ct);
    Task SendResolvedNotificationAsync(AlertEvent evt, CancellationToken ct);
    Task SendDuplicateNotificationAsync(AlertEvent evt, CancellationToken ct);
    Task SendErrorNotificationAsync(string error, CancellationToken ct);
    Task SendDailySummaryAsync(DailySummaryDto summary, CancellationToken ct);
    Task SendAuditNotificationAsync(AuditEvent audit, CancellationToken ct);
    Task SendRoutingCardAsync(AlertEvent evt, RoutingRule rule, CancellationToken ct);
}

// EventProcessingService only needs firing + resolved — forced to depend on 5 methods it never calls
public class EventProcessingService
{
    private readonly ILarkNotification _lark; // 7 methods, uses 2

    public async Task ProcessAsync(AlertEvent evt, CancellationToken ct)
    {
        if (evt.IsResolved)
            await _lark.SendResolvedNotificationAsync(evt, ct);
        else
            await _lark.SendFiringNotificationAsync(evt, ct);
    }
}

// DailySummaryCronService only needs summary — depends on 6 methods it never calls
public class DailySummaryCronService
{
    private readonly ILarkNotification _lark; // 7 methods, uses 1
}
```

## After: Segregated by Consumer

```csharp
// Each consumer gets exactly what it needs
public interface IAlertNotification
{
    Task SendFiringAsync(AlertEvent evt, CancellationToken ct);
    Task SendResolvedAsync(AlertEvent evt, CancellationToken ct);
}

public interface IDuplicateNotification
{
    Task SendDuplicateAsync(AlertEvent evt, CancellationToken ct);
    Task SendErrorAsync(string error, CancellationToken ct);
}

public interface ISummaryNotification
{
    Task SendDailySummaryAsync(DailySummaryDto summary, CancellationToken ct);
}

public interface IAuditNotification
{
    Task SendAuditAsync(AuditEvent audit, CancellationToken ct);
}

// Single implementation can implement all — consumers only see what they need
public class LarkNotificationService : IAlertNotification, IDuplicateNotification,
    ISummaryNotification, IAuditNotification
{
    // All methods implemented — no lies, no NotImplementedException
}

// Consumers are now precise
public class EventProcessingService
{
    private readonly IAlertNotification _alerts; // 2 methods, uses 2 — perfect fit
}

public class DailySummaryCronService
{
    private readonly ISummaryNotification _summary; // 1 method, uses 1 — perfect fit
}
```

**Each consumer depends on exactly the methods it uses. Adding `IRoutingNotification` doesn't force changes to `EventProcessingService`.**
