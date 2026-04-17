---
description: "Health diagnostic: context budget, structure, observability gaps, stale refs. Flags: --sprint --json"
---

# Harness Health Check

Run the harness health diagnostic to assess the overall state of the orchestrator harness.

```bash
python3 scripts/harness-obs.py --health
```

## What it checks

- **Context Budget** — Estimates token overhead from CLAUDE.md, skills, agents, playbooks, and MCP servers. Penalizes as total approaches 20K tokens.
- **Structure** — Verifies expected harness files exist (orchestrator.md, CLAUDE.md, agent defs, playbooks).
- **Observability Coverage** — Checks which event types are logged in observability.jsonl vs the 9 expected types.
- **Stale References** — Scans harness .md files for file path references and checks they still exist on disk.
- **Session Metrics** — Incorporates the existing harness composite score (ship rate, cache efficiency, etc.).

## Options

- `--json` — Output machine-readable JSON instead of the formatted report.

## Health Score

Composite 0-100 from 5 weighted components:
- Context budget (20%): lower overhead = higher score
- Structure (15%): present files / expected files
- Observability (10%): logged event types / expected types
- Stale refs (15%): valid refs / total refs
- Session metrics (40%): existing composite / 100
