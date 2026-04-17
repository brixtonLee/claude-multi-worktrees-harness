# LSP — Before/After Examples

## Before: Subtype Breaks Base Contract

```csharp
// Base repository — consumers expect all methods to work
public class GenericRepository<T> where T : BaseEntity
{
    protected readonly AppDbContext _db;
    public virtual async Task<T?> GetByIdAsync(Guid tenantId, Guid id)
        => await _db.Set<T>().FirstOrDefaultAsync(e => e.TenantId == tenantId && e.Id == id);

    public virtual async Task AddAsync(T entity)
    {
        _db.Set<T>().Add(entity);
        await _db.SaveChangesAsync();
    }
}

// Read-only subtype — BREAKS the contract
public class AuditLogRepository : GenericRepository<AuditLogEntry>
{
    // Consumer calls AddAsync expecting it to work — SURPRISE
    public override Task AddAsync(AuditLogEntry entity)
        => throw new NotSupportedException("Audit logs are added via IAuditLog only");
}

// Consumer code now needs special-case handling — LSP violated
public async Task ProcessBatch<T>(GenericRepository<T> repo, List<T> items) where T : BaseEntity
{
    foreach (var item in items)
    {
        // This BLOWS UP if repo is AuditLogRepository
        await repo.AddAsync(item);
    }
}
```

## After: Separate Interfaces by Capability

```csharp
// Read and write are separate contracts
public interface IReadRepository<T> where T : BaseEntity
{
    Task<T?> GetByIdAsync(Guid tenantId, Guid id);
    Task<PagedList<T>> GetPagedAsync(Guid tenantId, int page, int pageSize);
}

public interface IWriteRepository<T> where T : BaseEntity
{
    Task AddAsync(T entity);
}

// Full repo implements both — no lies
public class InvoiceRepository : IReadRepository<Invoice>, IWriteRepository<Invoice>
{
    public async Task<Invoice?> GetByIdAsync(Guid tenantId, Guid id) { /* works */ }
    public async Task AddAsync(Invoice entity) { /* works */ }
}

// Audit repo only implements read — never promises write capability
public class AuditLogQueryRepository : IReadRepository<AuditLogEntry>
{
    public async Task<AuditLogEntry?> GetByIdAsync(Guid tenantId, Guid id) { /* works */ }
    // No AddAsync — it's not in the interface, no lie to break
}

// Consumer code is safe — compiler prevents passing read-only repo to write methods
public async Task ProcessBatch<T>(IWriteRepository<T> repo, List<T> items) where T : BaseEntity
{
    foreach (var item in items)
        await repo.AddAsync(item); // AuditLogQueryRepository can't be passed here — type-safe
}
```

**The compiler enforces the contract. No runtime surprises.**
