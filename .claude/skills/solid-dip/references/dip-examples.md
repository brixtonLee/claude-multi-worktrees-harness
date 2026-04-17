# DIP — Before/After Examples

## Before: Background Service Depends on Concretions

```csharp
public class AutoResolveBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;

    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            using var scope = _scopeFactory.CreateScope();

            // VIOLATION: resolves concrete classes, not interfaces
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var lark = scope.ServiceProvider.GetRequiredService<LarkNotificationService>();

            var expired = await db.AlertInstances
                .Where(ai => ai.Status == "firing" && ai.LastUpdated < DateTime.UtcNow.AddHours(-1))
                .ToListAsync(ct);

            foreach (var instance in expired)
            {
                instance.Status = "resolved";  // Anemic model — public setter
                await lark.SendResolvedNotificationAsync(instance, ct);  // concrete dependency
            }

            await db.SaveChangesAsync(ct);
            await Task.Delay(TimeSpan.FromMinutes(1), ct);
        }
    }
}
```

**Problems: depends on AppDbContext (concrete), LarkNotificationService (concrete), contains business logic (should be in a service), uses public setters (anemic model).**

## After: Depends on Abstractions, Delegates to Service

```csharp
public class AutoResolveBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<AutoResolveBackgroundService> _logger;

    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();

                // Resolves INTERFACE — not concrete class
                var resolver = scope.ServiceProvider.GetRequiredService<IAutoResolveService>();
                await resolver.ResolveExpiredInstancesAsync(ct);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Auto-resolve cycle failed");
            }

            await Task.Delay(TimeSpan.FromMinutes(1), ct);
        }
    }
}

// Business logic lives in a proper service with injected abstractions
public class AutoResolveService : IAutoResolveService
{
    private readonly IAlertInstanceRepository _instanceRepo;
    private readonly IAlertNotification _notifications;
    private readonly IUnitOfWork _unitOfWork;

    public AutoResolveService(
        IAlertInstanceRepository instanceRepo,     // interface
        IAlertNotification notifications,           // interface
        IUnitOfWork unitOfWork)                     // interface
    {
        _instanceRepo = instanceRepo;
        _notifications = notifications;
        _unitOfWork = unitOfWork;
    }

    public async Task ResolveExpiredInstancesAsync(CancellationToken ct)
    {
        var expired = await _instanceRepo.GetExpiredAsync(TimeSpan.FromHours(1), ct);

        foreach (var instance in expired)
        {
            instance.Resolve();  // Rich domain model — encapsulated state change
            await _notifications.SendResolvedAsync(instance.LatestEvent, ct);
        }

        await _unitOfWork.SaveChangesAsync(ct);
    }
}
```

**Background service is thin (infrastructure concern only). Business logic is in a testable service with all dependencies as interfaces. `IServiceScopeFactory` usage is the accepted pattern for background services — this is the one place where service locator is valid.**
