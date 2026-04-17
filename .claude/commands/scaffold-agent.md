# Scaffold a new AI Agent

Generate all boilerplate files for a new agent named `$ARGUMENTS`.

## Instructions

Follow these steps exactly. Do NOT skip any step.

### Step 0: Validate

- The argument should be PascalCase (e.g., `CreditControl`, `CashFlowForecasting`).
- Read `src/AiAgents.Domain/Enums/AgentType.cs` and confirm this agent name doesn't already exist.
- If the name already exists, stop and tell the user.

### Step 1: Ask the user

Before generating code, ask:
1. **Tier:** Is this Tier 1 (Essential/Professional/Enterprise) or Tier 2 (Enterprise only)?
2. **Intents:** Which `IntentType` values should this agent handle? Show the existing values from `src/AiAgents.Domain/Enums/IntentType.cs`. Ask if a new IntentType needs to be added.
3. **Pipeline:** Orchestrated (1-2 Claude calls, mostly code) or Agentic (multi-turn reasoning)?

### Step 2: Add AgentType enum value

Edit `src/AiAgents.Domain/Enums/AgentType.cs`:
- Add the new value with the next sequential integer after the current highest value.
- Place it in the correct tier section (Tier 1 or Tier 2) with a comment if needed.

### Step 3: Add IntentType enum value (if needed)

If the user requested a new IntentType, edit `src/AiAgents.Domain/Enums/IntentType.cs`:
- Add the new value in the appropriate section (routed to agents).

### Step 4: Create the agent class

Create `src/AiAgents.Application/Agents/{Name}Agent.cs` following this pattern:

```csharp
using AiAgents.Application.Common.Interfaces;
using AiAgents.Application.Common.Models;
using AiAgents.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace AiAgents.Application.Agents;

public class {Name}Agent : BaseAgent
{
    public {Name}Agent(
        ILlmProvider llm,
        IBudgetController budget,
        IAppDbContext db,
        ILogger<{Name}Agent> logger)
        : base(llm, budget, db, logger)
    {
    }

    public override AgentType Type => AgentType.{Name};

    public override IReadOnlySet<IntentType> SupportedIntents { get; } =
        new HashSet<IntentType> { /* selected intents */ };

    // Tier 1: all plans. Tier 2: Enterprise only.
    public override bool IsAvailableForPlan(TenantPlan plan) =>
        plan >= TenantPlan.Essential; // or TenantPlan.Enterprise for Tier 2

    protected override async Task<AgentResult> ExecuteAsync(
        NormalizedInput input, CancellationToken cancellationToken)
    {
        // Step 1: Budget check
        var budgetStatus = await Budget.CheckBudgetAsync(input.TenantId, cancellationToken);
        if (!budgetStatus.IsWithinBudget)
            return AgentResult.Failed(Type, "Daily budget exceeded. Message queued for processing.");

        // Step 2: TODO — implement agent logic
        // For orchestrated agents: single Claude call + code logic
        // For agentic agents: multi-turn reasoning loop

        return AgentResult.Succeeded(Type, "Processing complete.");
    }
}
```

### Step 5: Register in DI

Edit `src/AiAgents.Infrastructure/InfrastructureServiceRegistration.cs`:
- Add `using AiAgents.Application.Agents;` if not already present.
- Add `services.AddScoped<IAgent, {Name}Agent>();` inside `AddInfrastructure`, after the WhatsApp section, in an "// Agents" section.

### Step 6: Create unit test

Create `tests/AiAgents.Application.Tests/Agents/{Name}AgentTests.cs`:

```csharp
using AiAgents.Application.Agents;
using AiAgents.Application.Common.Interfaces;
using AiAgents.Application.Common.Models;
using AiAgents.Domain.Enums;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace AiAgents.Application.Tests.Agents;

public class {Name}AgentTests
{
    private readonly Mock<ILlmProvider> _llm = new();
    private readonly Mock<IBudgetController> _budget = new();
    private readonly Mock<IAppDbContext> _db = new();
    private readonly Mock<ILogger<{Name}Agent>> _logger = new();

    private {Name}Agent CreateAgent() =>
        new(_llm.Object, _budget.Object, _db.Object, _logger.Object);

    [Fact]
    public void Type_ReturnsCorrectAgentType()
    {
        var agent = CreateAgent();
        agent.Type.Should().Be(AgentType.{Name});
    }

    [Fact]
    public void SupportedIntents_ContainsExpectedIntents()
    {
        var agent = CreateAgent();
        agent.SupportedIntents.Should().NotBeEmpty();
    }

    [Fact]
    public void IsAvailableForPlan_ReturnsExpected()
    {
        var agent = CreateAgent();
        // Adjust assertions based on tier
        agent.IsAvailableForPlan(TenantPlan.Enterprise).Should().BeTrue();
    }

    [Fact]
    public async Task ProcessAsync_BudgetExceeded_ReturnsFailed()
    {
        _budget.Setup(b => b.CheckBudgetAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new BudgetStatus { IsWithinBudget = false });

        var agent = CreateAgent();
        var input = new NormalizedInput
        {
            TenantId = Guid.NewGuid(),
            ContactId = Guid.NewGuid(),
            ConversationId = Guid.NewGuid(),
            MessageId = Guid.NewGuid(),
            Text = "test"
        };

        var result = await agent.ProcessAsync(input);

        result.Success.Should().BeFalse();
        result.ErrorMessage.Should().Contain("budget");
    }
}
```

### Step 7: Verify build

Run: `dotnet build AiAgents.sln`

If the build fails, fix the errors. Do NOT skip this step.

### Step 8: Report

Tell the user what was created:
- Agent class path
- Enum values added
- DI registration
- Test file path
- Build result
