---
name: services-interfaces
description: "Service interfaces in Application, implementations in Infrastructure, DI wiring. Use when creating services, external clients, or registering dependencies."
context:
  - .claude/skills/solid-isp/SKILL.md
  - .claude/skills/solid-srp/SKILL.md
---

# Skill: Services & Interfaces

## Interface Pattern (Application Layer)

```csharp
public interface IChatClient
{
    Task<ChatResponse> ChatAsync(ChatRequest request, CancellationToken ct = default);
}

public interface IBudgetController
{
    Task<bool> CanCallAsync(Guid tenantId, CancellationToken ct = default);
    Task RecordUsageAsync(Guid tenantId, TokenUsage usage, CancellationToken ct = default);
}
```

## Implementation (Infrastructure Layer)

```csharp
public sealed class ClaudeChatClient : IChatClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ClaudeChatClient> _logger;

    public ClaudeChatClient(HttpClient httpClient, ILogger<ClaudeChatClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<ChatResponse> ChatAsync(ChatRequest request, CancellationToken ct = default)
    { /* Claude API call */ }
}
```

## DI Registration

```csharp
public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
{
    services.AddDbContext<AppDbContext>(o => o.UseNpgsql(config.GetConnectionString("Default")));
    services.AddScoped<IChatClient, ClaudeChatClient>();
    services.AddScoped<IBudgetController, BudgetController>();
    return services;
}
```

## Rules

- Interfaces in `Application/Common/Interfaces/` — implementations in `Infrastructure/`
- One interface per concern — no god interfaces
- All methods include `CancellationToken ct = default`
- Scoped lifetime for anything touching DbContext or tenant state
- Singleton only for stateless utilities
- **NEVER** resolve via `IServiceProvider` manually — use constructor injection
- **NEVER** register Infrastructure types in Application's DI class

## Location

```
src/AiAgents.Application/Common/Interfaces/   ← ILlmProvider.cs, IBudgetController.cs
src/AiAgents.Infrastructure/Llm/Claude/       ← ClaudeLlmProvider.cs, ClaudeOptions.cs
src/AiAgents.Infrastructure/InfrastructureServiceRegistration.cs
```
