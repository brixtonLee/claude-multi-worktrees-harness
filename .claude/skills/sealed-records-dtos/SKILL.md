---
name: sealed-records-dtos
description: "Immutable DTOs using sealed records, mapping patterns. Use when creating request/response DTOs or entity-to-DTO mapping."
context:
  - .claude/skills/solid-lsp/SKILL.md
  - .claude/skills/solid-srp/SKILL.md
---

# Skill: Sealed Records & DTOs

## Pattern

```csharp
// Outbound — API returns
public sealed record InvoiceDto(Guid Id, string VendorName, decimal TotalAmount,
    string Status, decimal ConfidenceScore, DateTime CreatedAt);

// Inbound — API receives
public sealed record CreateInvoiceDto(string VendorName, decimal TotalAmount, DateTime InvoiceDate);

// Paged response
public sealed record PagedListDto<T>(List<T> Items, int TotalCount, int Page, int PageSize);
```

## Rules

- **Always `sealed record`** — not class, not struct, not unsealed record
- No logic in DTOs — pure data carriers
- No validation attributes — use FluentValidation
- No domain entities returned from API — always map entity → DTO
- Nullable `?` only when genuinely optional
- Suffix: `Dto` outbound, `Create*Dto`/`Update*Dto` inbound
- DTOs/Models live in `Application/Common/Models/` — never in Domain

## Mapping: Entity → DTO

Explicit extension methods, not AutoMapper:

```csharp
public static class InvoiceMappings
{
    public static InvoiceDto ToDto(this Invoice invoice) => new(
        invoice.Id, invoice.VendorName, invoice.TotalAmount,
        invoice.Status.ToString(), invoice.ConfidenceScore, invoice.CreatedAt);
}
```

## Location

```
src/AiAgents.Application/Common/Models/     ← ExtractionDtos.cs, AgentResult.cs, etc.
```
