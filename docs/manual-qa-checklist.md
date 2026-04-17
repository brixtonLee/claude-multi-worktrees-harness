# Manual QA Checklist

> **Purpose:** Tracks acceptance criteria that passed code verification (SHIP verdict) but require manual/runtime testing.
> ORCHESTRATOR appends here during SHIP handling when unchecked acceptance criteria remain.
> User checks items off after manual verification.

---

## Format

```
### [YYYY-MM-DD] [Sprint Goal]
**Branch:** [branch name]
**Verdict:** SHIP
**Unverified acceptance criteria:**
- [ ] [criterion]
```

---

## Entries

<!-- Append new entries below. Check off items after manual verification. -->

### [2026-04-06] Lark Topic + Resolved Notification
**Branch:** develop-brixton
**Verdict:** SHIP
**Unverified acceptance criteria:**
- [ ] Firing event card body shows `📡 Topic: {topic}` when sourced from Kafka
- [ ] REST-sourced events show no topic line (null-guard)
- [ ] Resolved events trigger a Lark thread reply to the original firing card
- [ ] Resolved reply title has `[Grafana]/[BIT]` badge prefix
- [ ] Resolved reply body includes firing event ID

### [2026-04-09] Add Severity Rule Details to Firing Alert Event Notification
**Branch:** release/2026.04.09-0.1.9
**Verdict:** SHIP
**Unverified acceptance criteria:**
- [ ] `dotnet test --filter "SeverityRuleEngineService"` passes (blocked by testhost lock at SHIP time)
- [ ] Firing Lark notification includes severity rule name, formula, field scores, and final score when a severity rule matched
- [ ] Firing Lark notification without matching severity rule shows no severity details section

### [2026-04-10] Fix Resolved Events Sent as Firing in Lark Routing
**Branch:** sprint/003
**Verdict:** SHIP
**Unverified acceptance criteria:**
- [ ] Resolved events produce a standalone card with green header in routing channels
- [ ] Resolved card title includes source prefix: `[Source] checkmark Title`
- [ ] Firing events continue to use existing card builder (unchanged)

### [2026-04-10] Remove Severity Color Header from Lark Card
**Branch:** sprint/002
**Verdict:** SHIP
**Unverified acceptance criteria:**
- [ ] Firing notification title is `[Source] {emoji} {Title}` with no severity tag
- [ ] No color template applied to firing notification card header (Lark defaults to blue)
- [ ] Resolved/duplicate/error cards unaffected

### [2026-04-10] Fix Daily Summary Timezone Error + Startup Run
**Branch:** sprint/004
**Verdict:** SHIP
**Unverified acceptance criteria:**
- [ ] No Npgsql timezone error when querying daily summary
- [ ] On startup, daily summary Lark card is sent immediately with UTC 00:00-to-now data
- [ ] Scheduled cron behavior unchanged (full timezone day)

### [2026-04-10] Severity Rule Audit Notifications via Lark
**Branch:** sprint/005
**Verdict:** SHIP
**Unverified acceptance criteria:**
- [ ] Create severity rule triggers audit Lark card with blue header, rule details, and CreatedBy
- [ ] Update severity rule triggers audit Lark card with orange header showing before/after comparison
- [ ] Delete severity rule triggers audit Lark card with red header and deleted rule details
- [ ] Enable severity rule triggers audit Lark card with green header
- [ ] Disable severity rule triggers audit Lark card with grey header
- [ ] Audit notification failure does not block the main API response

### [2026-04-10] Change Daily Summary Duplicate Events Query
**Branch:** sprint/006
**Verdict:** SHIP
**Unverified acceptance criteria:**
- [ ] All existing tests pass (pre-existing endpoint/severity test failures are known and unrelated)
- [ ] Daily summary Lark card shows correct duplicate counts grouped by matching_event_id
- [ ] Duplicate detail lines display timestamps in (HH:mm ~ HH:mm) format
