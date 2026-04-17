---
description: "Entropy scanner: duplicates, oversized files, orphans, TODOs, contradictions, staleness. Flags: --json"
---

# Harness Entropy Scanner

Measure harness documentation complexity, redundancy, and decay signals.

```bash
python3 scripts/harness-obs.py --entropy
```

## What it scans

- **Duplicate Rules** — Normalized rule-like lines that appear in multiple harness files.
- **File Sizes** — Files exceeding their type-specific line thresholds (CLAUDE.md: 150, skills: 80, playbooks/agents: 250).
- **Orphaned Sections** — Markdown headers with no content before the next header.
- **TODO/FIXME/HACK** — Unresolved markers in harness documentation.
- **Contradictions** — Potential conflicts between "never X" and "always X" rules across files.
- **Staleness** — Files not modified in over 30 days.

## Options

- `--json` — Output machine-readable JSON instead of the formatted report.

## Entropy Score

0-100 where lower is better (cleaner harness):
- Duplicates: 5 pts each (cap 30)
- Oversized files: 5 pts each (cap 20)
- Orphaned sections: 3 pts each (cap 15)
- TODOs: 2 pts each (cap 10)
- Contradictions: 10 pts each (cap 20)
- Stale files: 2 pts each (cap 10)
