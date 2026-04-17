# Sprint 008 Context — Convert 3 Agents to Claude Native tool_use

## Sprint Info
**ID:** 008
**Branch:** sprint/8
**Worktree:** (in-tree)
**Merge Target:** integration/master-20260416

## Current State
**Last Verdict:** SHIP — Convert 3 agents to Claude native tool_use — 2026-04-16
**Date:** 2026-04-16
**Sprint Start Commit:** eb4b6d4
**Sprint Started At:** 2026-04-16T00:00:00Z
**Baseline Build:** pass
**Baseline Tests:** pending (skipped — build baseline sufficient)
**Compaction Count:** 0

## File Manifest
### To Modify
- `src/AiAgents.Application/Agents/ExpenseClaimProcessingAgent.cs:L50-145` — Replace BuildSkillAwarePromptAsync + Llm.ExtractFromImageAsync with BuildSoulPromptAsync + BuildSkillToolsAsync + CompleteWithToolLoopAsync. Add try/catch.
- `src/AiAgents.Application/Agents/ReceiptCategorizationAgent.cs:L63-233` — Replace BuildSkillAwarePromptAsync + Llm.ExtractFromImageAsync with tool_use pattern. Remove manual skill lookups (L124-156). Adjust downstream refs.
- `src/AiAgents.Application/Agents/BankReconciliationAgent.cs:L80-275` — Replace 2 LLM call sites with tool_use pattern. Lazy skillTools init. Image extraction (L114) + categorization (L234).

### To Read (reference only)
- `src/AiAgents.Application/Agents/InvoiceProcessingAgent.cs:L80-160` — Reference pattern for tool_use conversion
- `src/AiAgents.Application/Agents/BaseAgent.cs:L60-138` — BuildSoulPromptAsync, BuildSkillToolsAsync, CompleteWithToolLoopAsync signatures
