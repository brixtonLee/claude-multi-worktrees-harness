# Sprint 008 Plan — Convert 3 Agents to Claude Native tool_use

## Task: Convert agents from inline skill injection to Claude native tool_use
**Complexity:** medium
**Scope:** Convert ExpenseClaimProcessingAgent, ReceiptCategorizationAgent, BankReconciliationAgent to use BuildSoulPromptAsync + BuildSkillToolsAsync + CompleteWithToolLoopAsync. DocumentChaserAgent excluded (no LLM calls). InvoiceProcessingAgent excluded (already converted).
**Approach:** Mechanical pattern replacement following InvoiceProcessingAgent as reference. Each agent swaps BuildSkillAwarePromptAsync for BuildSoulPromptAsync, adds BuildSkillToolsAsync, attaches tools to LlmRequest, replaces direct LLM calls with CompleteWithToolLoopAsync.

### Subtasks
- [x] 1. Convert ExpenseClaimProcessingAgent — layer: Application — files: ExpenseClaimProcessingAgent.cs — parallel-group: A — check-profile: full
- [x] 2. Convert ReceiptCategorizationAgent — layer: Application — files: ReceiptCategorizationAgent.cs — parallel-group: A — check-profile: full
- [x] 3. Convert BankReconciliationAgent — layer: Application — files: BankReconciliationAgent.cs — parallel-group: A — check-profile: full

### Key Details

**Reference pattern (InvoiceProcessingAgent L92-144):**
```csharp
var systemPrompt = await BuildSoulPromptAsync(tenantId, instructions, ct);
var skillTools = await BuildSkillToolsAsync(input.TenantId, cancellationToken);
var request = new LlmRequest { ..., Tools = skillTools.Count > 0 ? skillTools : null };
response = await CompleteWithToolLoopAsync(request, tenantId, imageData, mimeType, maxToolTurns: 3, ct);
```

**Per-agent specifics:**

1. **ExpenseClaimProcessingAgent** (simplest):
   - Swap prompt builder, add skill tools, replace `Llm.ExtractFromImageAsync` with `CompleteWithToolLoopAsync`
   - Add missing try/catch for `LlmUnavailableException` and `OperationCanceledException`
   - Add tool-use instruction mentioning policy rules, claim patterns, merchant aliases

2. **ReceiptCategorizationAgent** (moderate):
   - Swap prompt builder, add skill tools, replace `Llm.ExtractFromImageAsync` with `CompleteWithToolLoopAsync`
   - Remove manual skill lookups L124-156 (LoadSkillsAsync, FindRule for MerchantAlias/CategoryMapping/DeductibilityOverride)
   - Update downstream: `merchantName` = `dto.MerchantName`, `rawCategory` = `dto.Category` (no skill override variables)
   - Keep `MalaysianTaxRules.GetDeductibility` as deterministic fallback
   - Keep DeductibilityOverride skill descriptor
   - Add tool-use instruction mentioning merchant aliases, category mappings, deductibility overrides

3. **BankReconciliationAgent** (most complex — 2 call sites):
   - Declare `List<LlmToolDefinition>? skillTools = null;` before CSV/image branch
   - **Image extraction (L114-148):** Swap prompt, `skillTools ??= await BuildSkillToolsAsync(...)`, replace `Llm.ExtractFromImageAsync` with `CompleteWithToolLoopAsync`
   - **Categorization (L234-273):** Swap prompt, `skillTools ??= await BuildSkillToolsAsync(...)`, replace `Llm.CompleteAsync` with `CompleteWithToolLoopAsync` (text-only, no imageData)
   - Keep all existing try/catch blocks
   - Add tool-use instructions mentioning description categories, matching hints, bank quirks

### Acceptance Criteria
- [x] No remaining calls to `BuildSkillAwarePromptAsync` in the 3 converted agents
- [x] All 3 agents use `BuildSoulPromptAsync` + `BuildSkillToolsAsync` + `CompleteWithToolLoopAsync`
- [x] All 3 agents set `Tools = skillTools.Count > 0 ? skillTools : null` on LlmRequest
- [x] All 3 agents have try/catch for `LlmUnavailableException` and `OperationCanceledException`
- [x] ReceiptCategorizationAgent has no manual `LoadSkillsAsync`/`FindRule` calls
- [x] BankReconciliationAgent uses lazy `??=` for skillTools initialization
- [x] `dotnet build AiAgents.sln` passes
- [x] `dotnet test AiAgents.sln` passes

### Rework Items
