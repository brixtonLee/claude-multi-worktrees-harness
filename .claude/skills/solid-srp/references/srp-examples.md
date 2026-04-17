# SRP — Before/After Examples

## Before: God Service

```csharp
public class AlertEventService
{
    private readonly AppDbContext _db;
    private readonly ILarkNotification _lark;
    private readonly ILogger<AlertEventService> _logger;
    private readonly ISeverityRuleEngine _severityEngine;
    private readonly IEventRoutingService _routing;
    private readonly IDuplicateDetector _duplicateDetector;

    public async Task ProcessIncomingEventAsync(AlertEventDto dto, CancellationToken ct)
    {
        // 1. Parse and validate (reason to change: input format changes)
        var alertEvent = MapToEntity(dto);
        if (string.IsNullOrEmpty(alertEvent.Fingerprint))
            throw new ValidationException("Fingerprint required");

        // 2. Duplicate detection (reason to change: dedup logic changes)
        if (await _duplicateDetector.IsDuplicateAsync(alertEvent, ct))
        {
            await _lark.SendDuplicateNotificationAsync(alertEvent, ct);
            return;
        }

        // 3. Severity calculation (reason to change: severity rules change)
        var severity = await _severityEngine.CalculateAsync(alertEvent, ct);
        alertEvent.SetSeverity(severity);

        // 4. Persistence (reason to change: schema changes)
        _db.AlertEvents.Add(alertEvent);
        await _db.SaveChangesAsync(ct);

        // 5. Notification (reason to change: notification channels change)
        await _lark.SendFiringNotificationAsync(alertEvent, ct);

        // 6. Routing (reason to change: routing rules change)
        await _routing.RouteEventAsync(alertEvent, ct);
    }
}
```

**6 reasons to change in one class.**

## After: Split by Responsibility

```csharp
// Thin orchestrator — delegates to focused services
public class EventProcessingService : IEventProcessingService
{
    private readonly IEventValidationService _validation;
    private readonly IDuplicateDetector _duplicateDetector;
    private readonly ISeverityRuleEngine _severityEngine;
    private readonly IAlertEventRepository _eventRepo;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IEventNotificationService _notifications;

    public async Task ProcessAsync(AlertEventDto dto, CancellationToken ct)
    {
        var alertEvent = _validation.ValidateAndMap(dto);
        if (await _duplicateDetector.IsDuplicateAsync(alertEvent, ct)) return;

        var severity = await _severityEngine.CalculateAsync(alertEvent, ct);
        alertEvent.SetSeverity(severity);

        await _eventRepo.AddAsync(alertEvent);
        await _unitOfWork.SaveChangesAsync(ct);

        // Fire-and-forget notification — doesn't block processing
        _ = _notifications.NotifyAsync(alertEvent, ct);
    }
}

// Each service: one reason to change
public class EventValidationService : IEventValidationService { /* validation only */ }
public class DuplicateDetector : IDuplicateDetector { /* dedup only */ }
public class EventNotificationService : IEventNotificationService { /* notification only */ }
```

**Orchestrator is ~20 lines. Each delegate has one axis of change.**
