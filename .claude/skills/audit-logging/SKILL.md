---
name: audit-logging
description: "Append-only audit trail with JSONB details, 7-year retention. Use when implementing audit log writes or queries."
context:
  - .claude/skills/solid-isp/SKILL.md
---

# Skill: Audit Logging

## Pattern

```csharp
await _auditLog.LogAsync(new AuditLogEntry
{
    TenantId = ctx.TenantId,
    Action = "invoice_extracted",
    EntityType = "invoice",
    EntityId = invoice.Id,
    ActorType = "agent",
    ActorId = "InvoiceProcessingAgent",
    Details = JsonSerializer.SerializeToElement(new { source_channel = msg.Channel, cost_usd = extraction.Usage.Cost })
});
```

## Rules

- **APPEND ONLY** — no Update, no Delete methods exposed
- DB role: `GRANT SELECT, INSERT ON audit_log TO app_user`
- 7-year retention (Malaysian Companies Act)
- JSONB `details` column for flexible structured data
- Every entry includes `TenantId`
- `ActorType`: `"agent"`, `"user"`, `"system"`
- `Action`: snake_case verbs — `invoice_extracted`, `invoice_flagged`

## Interface

```csharp
public interface IAuditLog
{
    Task LogAsync(AuditLogEntry entry, CancellationToken ct = default);
    Task<PagedList<AuditLogEntry>> GetByEntityAsync(Guid tenantId, string entityType,
        Guid entityId, int page = 1, int pageSize = 50, CancellationToken ct = default);
}
```

## Location

```
src/AiAgents.Domain/Entities/                        ← AuditLogEntry.cs
src/AiAgents.Application/Common/Interfaces/          ← IAuditLogger.cs
src/AiAgents.Infrastructure/AuditLog/                ← AuditLogService.cs
```
