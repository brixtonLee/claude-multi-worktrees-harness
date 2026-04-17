---
name: solid-dip
description: "Dependency Inversion Principle — depend on abstractions, not concretions. Use when reviewing constructor dependencies, service registration, or code that uses 'new' for service instantiation."
---

# SOLID: Dependency Inversion Principle

## Definition

High-level modules should not depend on low-level modules. Both should depend on abstractions. In C# terms: constructor parameters should be interfaces, not concrete classes.

## The Smell

- `new ConcreteService()` inside another service's method
- Constructor parameter is a concrete class: `public MyService(LarkNotificationService lark)`
- Static method calls for business logic: `SeverityCalculator.Calculate(evt)`
- Direct `HttpClient` construction instead of `IHttpClientFactory`
- Service reads `appsettings.json` directly instead of `IOptions<T>`

## The Fix Pattern

```csharp
// VIOLATION: depends on concrete implementation
public class EventProcessingService
{
    private readonly LarkNotificationService _lark;        // concrete class
    private readonly AppDbContext _db;                       // concrete class
    private readonly SeverityRuleEngineService _severity;   // concrete class

    public EventProcessingService(
        LarkNotificationService lark,                       // ← can't substitute for tests
        AppDbContext db,
        SeverityRuleEngineService severity)
    { /* ... */ }
}

// FIX: depends on abstractions
public class EventProcessingService
{
    private readonly IAlertNotification _notifications;     // interface
    private readonly IAlertEventRepository _eventRepo;      // interface
    private readonly ISeverityRuleEngine _severityEngine;   // interface
    private readonly IUnitOfWork _unitOfWork;                // interface

    public EventProcessingService(
        IAlertNotification notifications,                   // ← injectable, mockable, substitutable
        IAlertEventRepository eventRepo,
        ISeverityRuleEngine severityEngine,
        IUnitOfWork unitOfWork)
    { /* ... */ }
}
```

## Common C# Traps

- **`IOptions<T>` is DIP-compliant** — it's an abstraction over configuration. Directly reading `IConfiguration["Key"]` in a service is not (depends on the config shape).
- **`IServiceProvider` is an anti-pattern** — manually resolving services via `provider.GetService<T>()` inside a service defeats DIP. Use constructor injection. Exception: background services that need scoped services via `IServiceScopeFactory`.
- **"But I need a factory"** — if you genuinely need runtime creation, inject `Func<T>` or a factory interface, not `IServiceProvider`.
- **DbContext is a special case** — in repository implementations, `AppDbContext` in the constructor is acceptable because the repository IS the infrastructure boundary. The Application layer should never see `AppDbContext`.

## Where DIP Lives in Clean Architecture

```
Application layer defines:    IAlertEventRepository, ISeverityRuleEngine, IChatClient
Infrastructure implements:    AlertEventRepository, SeverityRuleEngineService, ClaudeChatClient
API layer wires:              services.AddScoped<IAlertEventRepository, AlertEventRepository>();
```

The Application layer never knows Infrastructure exists. The API layer's DI registration is the only place where concrete meets abstract.

## Interaction with Other Principles

- DIP is the foundation that makes OCP possible (you can add new implementations without changing consumers)
- DIP + ISP: small interfaces are easier to implement and substitute
- DIP makes testing possible: inject mocks for all dependencies

## Examples

Read `${CLAUDE_SKILL_DIR}/references/dip-examples.md` for before/after C# code.
