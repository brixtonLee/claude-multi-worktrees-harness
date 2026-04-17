---
name: solid-srp
description: "Single Responsibility Principle — a class should have only one reason to change. Use when reviewing or creating classes, services, or agents. Detect God classes, mixed concerns."
---

# SOLID: Single Responsibility Principle

## Definition

A class should have only one reason to change. If you can describe what a class does using "AND", it likely violates SRP.

## The Smell — How to Detect Violations

- Class has 5+ injected dependencies in constructor
- Class name contains "Manager", "Helper", "Utility", "Processor" (vague responsibility)
- Single method does validation AND persistence AND notification AND logging
- Changes to notification logic force you to retest invoice parsing logic
- Class exceeds ~200 lines

## The Fix Pattern

Split by axis of change. Each resulting class has one clear job:

```
BEFORE: InvoiceProcessingService (validates, persists, notifies, logs, deduplicates)
AFTER:
├── InvoiceValidationService    — validates invoice fields
├── InvoiceRepository           — persists to database
├── LarkNotificationHandler     — sends Lark notifications
├── DuplicateDetectionService   — checks for duplicates
└── InvoiceProcessingAgent      — orchestrates the above (thin glue layer)
```

## Common C# Traps

- **"But it's just one public method"** — a single `ProcessAsync` that's 150 lines long with 6 injected deps still violates SRP. The method has one entry point but many reasons to change.
- **Over-splitting** — creating `InvoiceCreator`, `InvoiceSaver`, `InvoiceValidator` when they always change together. If they're coupled, keep them together.
- **Static helper classes** — `InvoiceHelper` with 20 static methods is a SRP violation hiding behind a "utility" name.

## Interaction with Other Principles

- SRP violations often cause OCP violations (adding a new notification channel means modifying the God class)
- Fixing SRP often naturally satisfies ISP (smaller classes → smaller interfaces)

## Examples

Read `${CLAUDE_SKILL_DIR}/references/srp-examples.md` for before/after C# code.
