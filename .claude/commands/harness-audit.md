---
description: "Audit: file refs, skill coverage, agent defs, playbook consistency. Flags: --json"
---

# Harness Audit

Run structural integrity checks across the entire harness engineering kit.

```bash
python3 scripts/harness-obs.py --audit
```

## What it validates

- **File References** — Every file path referenced in harness .md files exists on disk.
- **Skill Coverage** — Every skill in `.claude/skills/` is referenced by at least one harness file.
- **Agent Definitions** — Coder and verifier agent files contain required sections (Return Format, Scratch File, etc.).
- **Playbook References** — Every playbook referenced in orchestrator.md exists.
- **Registry** — Active sprints in registry have valid worktree dirs and git branches.
- **Commands** — Slash command files reference scripts/files that exist.
- **Observability** — All expected event types from execution playbook are being logged.

## Options

- `--json` — Output machine-readable JSON instead of the formatted report.

## Verdicts

Each check returns PASS, WARN, or FAIL:
- **PASS** — Check passed, reference valid
- **WARN** — Non-critical issue (e.g., unreferenced skill)
- **FAIL** — Broken reference or missing required element
