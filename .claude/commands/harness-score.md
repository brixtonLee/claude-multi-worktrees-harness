---
description: "Score + per-sprint details. Flags: --sprint --agent --session --from/--to/--last --sort cost|tokens|duration --detail --json"
---

# Harness Score

Show the harness observability score and metrics. Supports filters: `--sprint`, `--agent`, `--session`, `--from/--to/--last`, `--sort`, `--detail`.

## Instructions

Run the harness observability script and present the results to the user.

1. Run: `python3 scripts/harness-obs.py --score $ARGUMENTS`
2. Present the output to the user as-is.
3. If the user asks for more detail, run: `python3 scripts/harness-obs.py`
4. If the user asks to save a snapshot, run: `python3 scripts/harness-obs.py --save`

## Score Components

- **Ship Rate (25%):** Ratio of shipped sprints vs archived. Higher = more productive.
- **Token Efficiency (20%):** Output tokens / total tokens. Higher = more useful work per token.
- **Cache Hit Rate (20%):** Cache reads / total input. Higher = better context reuse.
- **Compaction Score (15%):** Fewer compactions per session = better context management.
- **Agent Utilization (10%):** Coder+verifier tokens / total. Higher = better harness discipline.
- **Rework Score (10%):** Fewer rework cycles = cleaner first-pass code.

## Arguments

Pass arguments after the command: `/harness-score [args]`

### Filters
- `--sprint NNN` — Filter to a specific sprint (e.g., `--sprint 006`)
- `--agent <name>` — Filter by agent type: coder, verifier, explore, plan, scout, other
- `--session <id>` — Filter to a single session by ID
- `--from YYYY-MM-DD` — Include sessions from this date onward
- `--to YYYY-MM-DD` — Include sessions up to this date
- `--last Nd` — Shorthand for last N days (e.g., `--last 7d`)

### Sorting
- `--sort cost` — Sort sprints and agents by cost (descending)
- `--sort tokens` — Sort by total token usage (descending)
- `--sort duration` — Sort by time taken (descending)

### Display
- `--detail` — Expanded tables with per-session rows, input/output token columns, cache breakdown
- `--json` — Machine-readable JSON output
- `--save` — Save snapshot to `docs/sprints/observability.jsonl`
