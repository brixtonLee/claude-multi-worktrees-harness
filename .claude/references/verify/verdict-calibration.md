# Verdict Calibration Examples

> Read this file ONLY when making the final verdict decision. Do NOT read at the start of verification.

These examples define where the SHIP/REWORK line sits. Apply this judgment consistently.

### Example 1: Clear REWORK — Spec Contract Violation

Subtask: Add invoice processing with tax compliance validation
Findings:
- Pass 1: Build passes, tests pass
- Pass 3: `InvoiceProcessingAgent` processes invoices but response missing `TaxComplianceStatus`
  field — acceptance criteria says "include Malaysian SST compliance status per invoice".
  Agent returns raw invoice data without running compliance check.
- Pass 4: `ProcessAsync` not passing `CancellationToken` through to the LLM service call
Decision: REWORK — missing tax compliance field is a contract violation. The agent processes
invoices but skips a required acceptance criterion. CancellationToken gap is also a code quality fail.

### Example 2: Clear SHIP — Minor Polish Only

Subtask: Add expense claim CRUD endpoints
Findings:
- Pass 1: Build passes, 14 tests pass, format clean
- Pass 2: Architecture clean — service in Application, interface in Application/Common/Interfaces
- Pass 4: `ExpenseClaimRequest` validation message uses property name "ClaimAmount"
  instead of display name "Claim Amount (MYR)"
- Pass 4: Could consolidate duplicate currency formatting logic across two DTOs
Decision: SHIP WITH FOLLOW-UPS — functionally correct, validation message wording
and DTO consolidation are polish → tech-debt.md

### Example 3: Gray Zone → REWORK — Tests Pass But Runtime Wrong

Subtask: Add bank reconciliation matching with new confidence score field
Findings:
- Pass 1: Build passes, tests pass
- Pass 2: Architecture clean
- Pass 3: Matching logic in `BankReconciliationAgent` ✓, confidence score computed ✓,
  but `BudgetController` endpoint NOT updated to include the new field in its response DTO —
  clients won't see the confidence score. Acceptance criteria says "expose confidence score
  via API".
- Pass 4: No issues
Decision: REWORK — the reconciliation logic works internally but the field is invisible to
API consumers. The model's temptation is to SHIP because build/tests are green and the core
logic works. Resist it — an incomplete API surface means the feature is half-delivered.

### Example 4: Gray Zone → SHIP — Real Finding But Non-Blocking

Subtask: Implement document chaser agent for overdue invoice follow-ups
Findings:
- Pass 1: Build passes, 8 tests pass
- Pass 2: Architecture clean — agent in Application/Agents, inherits BaseAgent
- Pass 4: `DocumentChaserAgent` retries sending notifications on transient failure but
  without exponential backoff — could spam the notification service during extended outages.
  Mitigated by the notification service's idempotency check on `InvoiceId + NotificationType`.
- Pass 4: No structured logging on retry attempts — harder to diagnose in production
Decision: SHIP WITH FOLLOW-UPS — retry spam is caught by the existing idempotency constraint.
Backoff policy and structured logging are real but non-critical at current volume.
Both → tech-debt.md with context.

### Example 5: REWORK — Architecture Violation (Code Works)

Subtask: Add automated payroll data validation
Findings:
- Pass 1: Build passes, tests pass
- Pass 2: `PayrollController` in API layer directly queries the database via injected
  `AppDbContext` and performs validation logic inline — business logic belongs in an
  Application service, not in the controller. Controller also references
  `Infrastructure.Persistence` namespace directly — layer isolation violation.
- Pass 3: Acceptance criteria met functionally
Decision: REWORK — layer violation is a BLOCKER regardless of functional correctness.
Business logic in controller + direct Infrastructure reference violates clean architecture.
Working code with wrong architecture sets a precedent that compounds.
