---
name: async-patterns
description: "Async-all-the-way, CancellationToken threading, common pitfalls. Use when writing or reviewing async code."
---

# Skill: Async Patterns

## Rules

- All I/O methods are `async Task<T>` — no exceptions
- NEVER use `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()`
- Use `CancellationToken ct = default` on all async method signatures
- Pass `ct` through to all downstream async calls
- Suffix async methods with `Async`
- `ConfigureAwait(false)` is NOT needed in ASP.NET Core — don't add it

## Correct

```csharp
public async Task<Result<InvoiceDto>> ProcessAsync(CreateInvoiceDto dto, CancellationToken ct = default)
{
    var vendor = await _vendorRepo.FindFuzzyAsync(dto.TenantId, dto.VendorName, ct);
    await _invoiceRepo.AddAsync(invoice, ct);
    return Result<InvoiceDto>.Ok(invoice.ToDto());
}
```

## Wrong — DEADLOCK RISK

```csharp
public Result<InvoiceDto> Process(CreateInvoiceDto dto)
{
    var vendor = _vendorRepo.FindFuzzyAsync(dto.TenantId, dto.VendorName).Result; // BLOCKS
}
```
