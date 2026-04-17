---
description: "Cost analysis. Flags: --sprint --agent --session --from/--to/--last --sort cost|tokens|duration --json"
---

# Harness Cost Analysis

Run cost breakdown and optimization suggestions based on real session data. Supports filters: `--sprint`, `--agent`, `--session`, `--from/--to/--last`, `--sort`.

## Instructions

1. Run: `python3 scripts/harness-obs.py --cost $ARGUMENTS`
2. Present the output to the user with analysis and recommendations.

## What it shows

- **Per-Agent Cost** — Percentage of total cost consumed by each agent type (coder, verifier, scout, etc.).
- **Cost Per Shipped Sprint** — Total cost divided by shipped sprint count.
- **Rework Cost** — Estimated cost attributable to rework passes.
- **Model Mix** — Cost distribution across models (Opus, Sonnet, Haiku) with concentration warnings.
- **Trend** — Cost direction over last 3 sprints (rising/falling/stable).
- **Suggestions** — Actionable recommendations based on detected patterns.

## Arguments

Pass arguments after the command: `/harness-cost [args]`

### Filters
- `--sprint NNN` — Filter to a specific sprint (e.g., `--sprint 003`)
- `--agent <name>` — Filter by agent type: coder, verifier, explore, plan, scout, other
- `--session <id>` — Filter to a single session by ID
- `--from YYYY-MM-DD` — Include sessions from this date onward
- `--to YYYY-MM-DD` — Include sessions up to this date
- `--last Nd` — Shorthand for last N days (e.g., `--last 7d`)

### Sorting
- `--sort cost` — Sort sprints and agents by cost (descending)
- `--sort tokens` — Sort by total token usage (descending)
- `--sort duration` — Sort by time taken (descending)

### Output
- `--json` — Machine-readable JSON instead of the formatted report

## Suggestion triggers

- Opus > 80% of cost: consider Sonnet for explore/plan agents
- Rework cost > 20%: code quality issue consuming budget
- Cost per sprint trending up: review agent complexity
