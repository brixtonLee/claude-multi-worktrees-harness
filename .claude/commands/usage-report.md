# Usage Report

Show detailed harness observability: tokens, costs, models, agents, context window, and compaction data.

## Instructions

Run the harness observability script and present the full report to the user.

1. Run: `python3 scripts/harness-obs.py $ARGUMENTS`
2. Present the output to the user as-is.

If the user specifies a sprint, pass `--sprint NNN`.
If the user asks for JSON, pass `--json`.
If the user asks to save, also pass `--save`.

## Report Sections

The full report includes:
- **Harness Score** — composite quality metric with component breakdown
- **Tokens Per Sprint** — input, output, cache reads, cost, compactions per sprint
- **Tokens Per Agent** — breakdown by coder, verifier, explore, plan, other
- **Tokens Per Model** — breakdown by Opus, Sonnet, Haiku
- **Cost Summary** — total sessions, tokens, cost, compactions, ship/archive counts
- **Context Window** — cache reads/writes, read/write ratio, compactions per session

## Data Sources

- Claude Code session files: `~/.claude/projects/<project-id>/*.jsonl`
- Subagent sessions: `~/.claude/projects/<project-id>/<session>/subagents/*.jsonl`
- Orchestrator events: `docs/sprints/observability.jsonl`
- Sprint outcomes: `docs/completed-sprints.md`, `docs/archived-sprints.md`
