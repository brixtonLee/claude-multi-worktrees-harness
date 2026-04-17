# Sprint 008 Progress

> **Purpose:** Completed subtask archive for this sprint.
> **Updated by:** ORCHESTRATOR after each subtask completes.

---

## Entries

<!-- Append new entries below. -->

### [2026-04-16] Convert Agents to tool_use — Subtask 1: ExpenseClaimProcessingAgent
**Files changed:** src/AiAgents.Application/Agents/ExpenseClaimProcessingAgent.cs
**What was done:** Replaced BuildSkillAwarePromptAsync + Llm.ExtractFromImageAsync with BuildSoulPromptAsync + BuildSkillToolsAsync + CompleteWithToolLoopAsync. Added try/catch for LlmUnavailableException and OperationCanceledException.

### [2026-04-16] Convert Agents to tool_use — Subtask 2: ReceiptCategorizationAgent
**Files changed:** src/AiAgents.Application/Agents/ReceiptCategorizationAgent.cs
**What was done:** Replaced BuildSkillAwarePromptAsync + Llm.ExtractFromImageAsync with BuildSoulPromptAsync + BuildSkillToolsAsync + CompleteWithToolLoopAsync. Removed manual skill lookups (LoadSkillsAsync, FindRule for MerchantAlias/CategoryMapping/DeductibilityOverride). Updated downstream references to use dto.MerchantName and dto.Category directly.

### [2026-04-16] Convert Agents to tool_use — Subtask 3: BankReconciliationAgent
**Files changed:** src/AiAgents.Application/Agents/BankReconciliationAgent.cs
**What was done:** Converted both LLM call sites (image extraction + categorization) from BuildSkillAwarePromptAsync + direct LLM calls to BuildSoulPromptAsync + CompleteWithToolLoopAsync with lazy skillTools initialization via ??=.

### [2026-04-16] Fix — Update test mocks
**Files changed:** tests/AiAgents.Application.Tests/Agents/ReceiptCategorizationAgentTests.cs, tests/AiAgents.Application.Tests/Agents/BankReconciliationAgentTests.cs
**What was done:** Added BuildSoulPromptAsync, BuildToolDefinitionsAsync, and LoadSkillsAsync mocks to match the new tool_use pattern. All 308 tests pass.
