---
title: Keep Business Rules Out of the Data Layer
slug: keep-business-rules-out-of-the-data-layer
category: architecture
tags: [universal, architecture, layering]
works_with: all
severity: high
one_liner: "Business decisions hiding inside ORM models, repositories, and triggers"
---

# Keep Business Rules Out of the Data Layer

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from burying business decisions in ORM model methods, repository queries, and database triggers, where they execute invisibly and answer to no one.

**[Copy-paste ready version](../../install/keep-business-rules-out-of-the-data-layer.md)** — just the instruction block, no explanation.

## The Problem

The AI needs to apply a late fee when an invoice saves past its due date. The ORM model has a `save()` to override, so the fee logic goes there. Or the repository's `get_active_users()` quietly grows `AND plan != 'trial' AND last_login > NOW() - INTERVAL '90 days'` — a business definition of "active" encoded as a WHERE clause. Or, in the worst version, a database trigger starts adjusting balances. In every case a business decision now lives below the layer whose job is deciding things, and it fires whenever the storage machinery runs — including from migrations, admin scripts, bulk imports, and test fixtures that just wanted to save a row.

Logic in the data layer has two structural problems. It's invisible at the call site: `invoice.save()` reads as persistence, and nothing tells the reader a fee may be charged. And it can't be selectively invoked: every path that persists data gets the side effects, whether it wants them or not, which is why teams with fee-charging save hooks end up with `save(skip_hooks=True)` flags sprinkled everywhere — each one a confession.

AI assistants put logic there because the data layer is where the data already is. The model has the fields; the query already filters rows; the hook is a documented extension point. Each placement is locally convenient and architecturally upside-down.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Business Rules Out of the Data Layer

NEVER put business decisions in the data layer: no business logic in ORM lifecycle hooks (`save()`, `before_update`, signals), no business definitions baked into repository query methods, no database triggers or stored procedures that make domain decisions. The data layer stores and retrieves; the domain layer decides.

Logic below the domain layer executes invisibly on every persistence path — including the migrations, imports, and scripts that never asked for it.

- Side effects (fees, notifications, status changes) happen in an explicitly named domain operation — `apply_late_fee(invoice)`, called by whoever decides it's time — never in a save hook that fires whenever anything touches the row
- Repositories answer mechanical questions (`users_with_login_since(date)`), with parameters; the *business meaning* of "active" lives in one named domain function or spec that supplies those parameters
- ORM models can hold field-level derivations (`full_name`), but the moment a method consults plans, dates, or money to make a decision, it's domain logic in the wrong building
- Database constraints for integrity (foreign keys, uniqueness, NOT NULL) are good and encouraged — they enforce data shape, not business policy. Triggers that compute fees or flip statuses are policy in the basement
- If you find yourself adding a `skip_hooks` or `raw_save` flag, that's the architecture telling you the hook logic never belonged there

**Red flags that you're about to violate this:**
- "The save hook guarantees the rule always runs..."
- "The model already has all the fields the rule needs..."
- "I'll put the filter in the repository so callers can't get it wrong..."
- "A trigger means even manual SQL respects the rule..."
- "It's just one condition in the query..."

---

## Why It Works

1. **It distinguishes 'always runs' from 'always should run'.** Hook logic fires on every persistence path; the rule names the paths (migrations, imports, fixtures) where "guaranteed execution" is precisely the bug.

2. **It separates the question from the answer.** Repositories take parameters (mechanics); domain code supplies them (policy). The split means changing what "active" means is a one-place edit that no SQL audit is needed to find.

3. **It treats escape-hatch flags as a signal.** `skip_hooks=True` is the empirically reliable symptom that decisions got buried; teaching the AI to read it stops the second-order damage of adding more flags.

4. **It keeps the good parts of the database.** Blessing integrity constraints explicitly prevents the overcorrection — the rule targets policy in storage, not the existence of a competent schema.

## Origin

An invoicing system charged late fees from a `before_save` ORM hook. A data-cleanup script that fixed address typos re-saved 30,000 historical invoices one weekend, and the hook dutifully assessed late fees on every overdue one of them — about 4,100 customers were charged for invoices from previous fiscal years. The refund run took longer than the cleanup. The hook had been added years earlier with the rationale "this way the fee can never be forgotten"; the postmortem retitled that property "this way the fee can never be intended."
