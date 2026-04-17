---
name: solid-lsp
description: "Liskov Substitution Principle — subtypes must be substitutable for their base types without breaking behavior. Use when reviewing inheritance hierarchies, overridden methods, or interface implementations that throw NotImplementedException."
---

# SOLID: Liskov Substitution Principle

## Definition

If code works with `Base`, it must also work with `Derived` — no surprises, no exceptions, no changed contracts.

## The Smell

- Overridden method throws `NotImplementedException` or `NotSupportedException`
- Derived class silently ignores base contract (e.g., `Save()` that doesn't persist)
- Type-checking with `is` or `as` to decide behavior: `if (repo is ReadOnlyRepo) skip;`
- Consumer code has special-case handling for specific subtypes
- Collection of base type breaks when a derived type is added

## The Fix Pattern

If a subtype can't fulfill the full base contract, it shouldn't inherit from it. Use a narrower interface instead.

```csharp
// VIOLATION: ReadOnlyRepository inherits full repo but can't write
public class ReadOnlyAlertRepo : AlertEventRepository
{
    public override Task AddAsync(AlertEvent entity)
        => throw new NotSupportedException("Read-only repository");
}

// FIX: separate interfaces for read vs write
public interface IAlertEventReader
{
    Task<AlertEvent?> GetByIdAsync(Guid tenantId, Guid id);
    Task<PagedList<AlertEvent>> GetPagedAsync(Guid tenantId, AlertEventFilter filter);
}

public interface IAlertEventWriter
{
    Task AddAsync(AlertEvent entity);
}

// Full repo implements both — read-only consumers use only IAlertEventReader
public class AlertEventRepository : IAlertEventReader, IAlertEventWriter { /* ... */ }
```

## Common C# Traps

- **`ICollection<T>` in read-only contexts** — `ReadOnlyCollection` throws on `Add()`. If a method accepts `ICollection<T>` but gets a read-only one, LSP is violated. Use `IReadOnlyCollection<T>` instead.
- **Sealed record inheritance** — records support inheritance but `sealed` prevents it. Prefer `sealed record` for DTOs to avoid LSP traps entirely.
- **Async contract changes** — base returns `Task<T>`, override returns completed task synchronously and swallows exceptions. The contract says "I do async work" but the override lies.

## Interaction with Other Principles

- LSP violations often signal ISP violations (interface is too broad for some implementors)
- LSP + OCP: if adding a new subtype forces consumers to add type-checks, both are violated

## Examples

Read `${CLAUDE_SKILL_DIR}/references/lsp-examples.md` for before/after C# code.
