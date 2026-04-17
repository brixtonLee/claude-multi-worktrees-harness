---
name: agent-pipeline
description: "Orchestrated pipeline pattern (default) and agentic loop pattern, prompt building, budget integration. Use when implementing AI agent logic."
---

# Skill: Agent Pipeline

## Orchestrated Pipeline (default — 13 of 17 agents)

Maximum 1-2 Claude API calls per invocation. All validation is C# code, not LLM judgment.

```csharp
public async Task<AgentResponse> ProcessAsync(NormalizedMessage message, AgentContext ctx)
{
    var prompt = await _promptBuilder.BuildAsync(ctx.TenantId, AgentType.InvoiceProcessing);
    if (!await _budget.CanCallAsync(ctx.TenantId))
        return AgentResponse.Queued("Budget limit reached");

    var extraction = await _claude.ChatAsync(new ChatRequest { SystemPrompt = prompt, /* ... */ });
    await _budget.RecordUsageAsync(ctx.TenantId, extraction.Usage);

    // Steps 4-8: ALL pure C# code — validate, dedup, save, reply
    var invoice = ParseExtraction(extraction.Text);
    var soulResult = _soulGuard.Enforce(invoice, ctx);
    if (soulResult.MustReview) invoice.FlagForReview(string.Join("; ", soulResult.Violations));
    await _invoiceRepo.AddAsync(invoice);
    return AgentResponse.Success(ComposeReply(invoice));
}
```

## Agentic Loop (ONLY agents #4, #10, #13, #17)

Use only when multi-step reasoning is genuinely required. Hard cap: 5 iterations.

## Rules

- Budget check BEFORE every Claude call, record AFTER
- SOUL.md loaded first in prompt via `IPromptBuilder`
- All validation is C# code, not LLM judgment
- Parse response immediately — don't chain calls
- Template responses where possible
- Orchestrated agent implemented as agentic → flag and correct (cost is 4x)

## Location

```
src/AiAgents.Application/Agents/              ← InvoiceProcessingAgent.cs, BaseAgent.cs
src/AiAgents.Infrastructure/Llm/Claude/       ← ClaudeLlmProvider.cs, ClaudeRouterService.cs
```
