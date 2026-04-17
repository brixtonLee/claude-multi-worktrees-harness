---
name: entities
description: "Domain entities, BaseEntity, value objects, enums, domain events. Use when creating or modifying entities in the Domain layer."
context:
  - .claude/skills/solid-srp/SKILL.md
---

# Skill: Entities

## BaseEntity

```csharp
public abstract class BaseEntity
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid TenantId { get; private set; }
    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; private set; } = DateTime.UtcNow;

    private readonly List<IDomainEvent> _domainEvents = new();
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    protected void AddDomainEvent(IDomainEvent domainEvent) => _domainEvents.Add(domainEvent);
    public void ClearDomainEvents() => _domainEvents.Clear();

    protected void SetTenant(Guid tenantId)
    {
        if (TenantId != Guid.Empty) throw new DomainException("Tenant cannot be changed");
        TenantId = tenantId;
    }
}
```

## Rules

- Private setters on ALL properties — `{ get; private set; }`
- State changes via explicit methods with domain meaning (not public setters)
- Validation in constructor and state-change methods
- Domain events for side effects (not direct service calls)
- NEVER use `public set` — no anemic models
- NEVER put `[Required]`, `[MaxLength]` on entities — use EF Core fluent API
- Every entity has `TenantId` (UUID) — set once via `SetTenant()`
- Private parameterless constructor for EF Core materialization
- Navigation properties: `IReadOnlyCollection<T>` with private `List<T>` backing field
- Factory method pattern: `public static T Create(...)` instead of public constructor

## Value Objects

```csharp
public sealed record Money(decimal Amount, string Currency = "MYR")
{
    public Money { if (Amount < 0) throw new DomainException("Amount cannot be negative"); }
}
```

## Domain Events

```csharp
public sealed record InvoiceFlaggedEvent(Guid InvoiceId, string Reason) : IDomainEvent;
```

Raised inside entity methods via `AddDomainEvent()`. Dispatched after persistence.

## Location

```
src/AiAgents.Domain/Entities/      src/AiAgents.Domain/ValueObjects/
src/AiAgents.Domain/Enums/         src/AiAgents.Domain/Events/
```
