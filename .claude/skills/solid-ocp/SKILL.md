---
name: solid-ocp
description: "Open/Closed Principle — open for extension, closed for modification. Use when adding new variants (notification channels, file types, agent types) or reviewing switch/if-else chains on type."
---

# SOLID: Open/Closed Principle

## Definition

You should be able to add new behavior without modifying existing code. New variant = new class, not new `case` in a switch.

## The Smell

- `switch` or `if-else` chain on an enum/type that grows every time a new variant is added
- Adding a new notification channel requires modifying `NotificationService.cs`
- Adding a new file type requires modifying `FileProcessor.cs`
- Method has a comment like `// TODO: add case for new type here`

## The Fix Pattern — Strategy + DI Registration

```csharp
// 1. Define the contract
public interface INotificationProvider
{
    string ChannelType { get; }
    Task SendAsync(AlertEvent alertEvent, CancellationToken ct = default);
}

// 2. Each variant is a separate class
public class LarkNotificationProvider : INotificationProvider
{
    public string ChannelType => "lark";
    public async Task SendAsync(AlertEvent alertEvent, CancellationToken ct) { /* Lark API */ }
}

public class EmailNotificationProvider : INotificationProvider
{
    public string ChannelType => "email";
    public async Task SendAsync(AlertEvent alertEvent, CancellationToken ct) { /* SMTP */ }
}

// 3. Consumer iterates — no switch, no if-else
public class EventRoutingService
{
    private readonly IEnumerable<INotificationProvider> _providers;

    public async Task RouteAsync(AlertEvent evt, string channelType, CancellationToken ct)
    {
        var provider = _providers.FirstOrDefault(p => p.ChannelType == channelType)
            ?? throw new InvalidOperationException($"No provider for {channelType}");
        await provider.SendAsync(evt, ct);
    }
}

// 4. DI — adding a new channel = one new class + one line here
services.AddScoped<INotificationProvider, LarkNotificationProvider>();
services.AddScoped<INotificationProvider, EmailNotificationProvider>();
services.AddScoped<INotificationProvider, WebhookNotificationProvider>(); // ← NEW: no existing code modified
```

## Common C# Traps

- **Premature abstraction** — don't create a strategy pattern for 1 variant. Wait until you have 2+. YAGNI first, OCP when the second variant arrives.
- **Enum-based dispatch that's actually fine** — a switch on `InvoiceStatus` in a single mapper method is NOT an OCP violation. OCP applies when each case has *different behavior*, not different data.
- **Inheritance hierarchies** — prefer composition (strategy pattern) over deep inheritance chains.

## Interaction with Other Principles

- OCP often requires DIP (depend on `INotificationProvider`, not concrete classes)
- OCP + ISP: if the interface is too fat, new variants struggle to implement it

## Examples

Read `${CLAUDE_SKILL_DIR}/references/ocp-examples.md` for before/after C# code.
