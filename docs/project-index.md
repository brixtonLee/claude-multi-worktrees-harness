# Project Index — Agent Routing, Skill Routing

> Referenced by `orchestrator.md` and `coder.md`. Read on demand when planning subtasks, validating agent pipeline types, or understanding agent context during coding.
> Sprint roadmap is in `Dev Plans/dev-plan-v3.md` L10-L55.

---

## Agent Routing Table

When a task involves a specific business agent, verify the pipeline pattern (see `agent-pipeline/SKILL.md` for full details):

### Orchestrated Pipeline Agents (1-2 Claude calls max)
```
#1  Invoice Processing    → extract(1 call) → validate/dedup/save(code) → reply(template)
#2  Document Chaser       → check(code) → compose(template or 1 call) → send(code)
#3  Bank Reconciliation   → parse(code or 1 call) → match(code) → categorize(1 call)
#5  Receipt Categorization→ extract(1 call) → categorize/deductibility(code) → save(code)
#6  Payroll Collection    → prompt(template) → validate(code) → save(code)
#7  Tax Deadline          → check(code) → compose(template) → send(code)
#8  Report Generator      → query(code) → format(code) → generate PDF/Excel(code)
#11 Multi-Entity          → query(code) → aggregate(code) → report(code)
#12 SST Compliance        → calculate(code) → generate return(code)
#14 Expense Claims        → extract(1 call) → policy check(code) → flag/save(code)
#15 Instant Report        → query(code) → generate PDF(code) → send(code)
#16 E-Invoice             → validate(code) → generate XML(code) → submit API(code)
```

### Agentic Loop Agents (2-5 Claude calls)
```
#4  Client Query          → needs reasoning: RAG vs NL→SQL vs escalation
#10 Anomaly Detection     → needs reasoning: explain patterns
#13 Client Onboarding     → multi-turn conversational flow
#17 Audit Query Response  → needs reasoning: find relevant documents
```

### Hybrid Agent
```
#9  Audit Preparation     → mostly code checklist, agentic for gap analysis
```

If a developer tries to implement an orchestrated agent as agentic → flag and correct. The cost difference is 4x.

---

## Skill Routing Table

When decomposing subtasks, assign the relevant skill files from `.claude/skills/`:

| Subtask Type | Assign These Skills (from `.claude/skills/`) |
|-------------|----------------------------------------------|
| New entity / modify entity | `architecture-layers/SKILL.md` + `entities/SKILL.md` |
| New value object | `architecture-layers/SKILL.md` + `entities/SKILL.md` + `sealed-records-dtos/SKILL.md` |
| New enum | `architecture-layers/SKILL.md` + `entities/SKILL.md` |
| New DTO / modify DTO | `architecture-layers/SKILL.md` + `sealed-records-dtos/SKILL.md` |
| New repository interface | `architecture-layers/SKILL.md` + `repository-pattern/SKILL.md` |
| Repository implementation | `architecture-layers/SKILL.md` + `repository-pattern/SKILL.md` + `ef-core-config/SKILL.md` |
| New service interface | `architecture-layers/SKILL.md` + `services-interfaces/SKILL.md` |
| Service implementation | `architecture-layers/SKILL.md` + `services-interfaces/SKILL.md` |
| DI registration | `services-interfaces/SKILL.md` |
| EF Core configuration | `ef-core-config/SKILL.md` |
| DB migration | `ef-core-config/SKILL.md` |
| New agent pipeline | `architecture-layers/SKILL.md` + `agent-pipeline/SKILL.md` + `result-error-handling/SKILL.md` |
| Agent error handling | `result-error-handling/SKILL.md` + `agent-pipeline/SKILL.md` |
| Audit log integration | `audit-logging/SKILL.md` |
| File processing | `file-handling/SKILL.md` |
| Controller endpoint | `architecture-layers/SKILL.md` + `result-error-handling/SKILL.md` + `sealed-records-dtos/SKILL.md` |
| Write tests | `testing/SKILL.md` + skill for code under test |
| Any I/O code | `async-patterns/SKILL.md` (always include) |

Include this in each subtask line in `current-plan.md`:
```
- [ ] 1. Create Invoice entity — layer: Domain — skills: [architecture-layers/SKILL.md, entities/SKILL.md] — files: [...]
```
