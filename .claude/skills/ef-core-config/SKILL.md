---
name: ef-core-config
description: "EF Core fluent API configuration, table conventions, indexes, migrations, RLS. Use when configuring entities, creating migrations, or setting up database schema."
---

# Skill: EF Core Configuration

## Entity Configuration Pattern

```csharp
public class InvoiceConfiguration : IEntityTypeConfiguration<Invoice>
{
    public void Configure(EntityTypeBuilder<Invoice> builder)
    {
        builder.ToTable("invoices");
        builder.HasKey(i => i.Id);
        builder.Property(i => i.TenantId).IsRequired();
        builder.Property(i => i.VendorName).HasMaxLength(500).IsRequired();
        builder.Property(i => i.TotalAmount).HasPrecision(18, 2);
        builder.Property(i => i.Status).HasConversion<string>().HasMaxLength(50);
        builder.HasIndex(i => new { i.TenantId, i.CreatedAt });
        builder.Ignore(i => i.DomainEvents);
    }
}
```

## Rules

- **Fluent API only** — no data annotations on entities
- One config class per entity — `IEntityTypeConfiguration<T>`
- snake_case table names — `builder.ToTable("invoices")`
- Always index `TenantId` — it's in every WHERE clause via RLS
- Decimal: `(18, 2)` for money, `(5, 4)` for percentages
- Enum as string — `HasConversion<string>()`
- Ignore DomainEvents on every entity

## Migration Naming: `YYYYMMDD_Description`

## RLS (every table with TenantId)

```sql
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON invoices
    USING (tenant_id = current_setting('app.current_tenant')::uuid);
```

## Location

```
src/AiAgents.Infrastructure/Persistence/AppDbContext.cs
src/AiAgents.Infrastructure/Persistence/Configurations/
src/AiAgents.Infrastructure/Persistence/Migrations/
```
