---
title: Respect ORM Flush and Autocommit Semantics
slug: respect-orm-flush-and-autocommit
category: databases
tags: [universal, databases, orm]
works_with: all
severity: high
one_liner: "Guessing when the ORM actually writes, instead of knowing"
---

# Respect ORM Flush and Autocommit Semantics

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents bugs from wrong assumptions about when an ORM flushes, commits, or silently persists your changes.

**[Copy-paste ready version](../../install/respect-orm-flush-and-autocommit.md)** — just the instruction block, no explanation.

## The Problem

ORMs hide the moment of writing, and the AI fills the gap with a guess, usually a guess imported from a different ORM. It assumes `session.add(obj)` wrote the row (it didn't; it staged it). It assumes mutating an attribute on a loaded Django model is pending until something commits (it isn't pending anything; nothing persists until `.save()`, and then `.save()` writes immediately, all fields). It assumes a SQLAlchemy query mid-session won't touch the database state, not knowing autoflush just pushed its staged changes down so the query could see them. It writes a "dry run" that skips `commit()` but runs queries, and autoflush makes the dry run wet.

The failure shows up as both directions of wrong: changes the AI believed were saved that never were (missing `commit()`, mutation without `save()`), and changes the AI believed were unsaved that hit the database anyway (autoflush, `save()` inside a helper, an ORM hook with side effects). Both produce the worst kind of bug, code that reads correctly under one ORM's semantics and does something else under the ORM actually in use.

There's no universal rule for when ORMs write, which is precisely the point: the AI must check the one in front of it instead of pattern-matching from the others.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Respect ORM Flush and Autocommit Semantics

NEVER assume when an ORM writes to the database; verify the semantics of the ORM actually in use. Flush, commit, autoflush, and unit-of-work behavior differ between ORMs, and a correct pattern in one is a bug in another.

- Answer these explicitly (from the docs or the project's existing code) before writing persistence logic:
  - Does creating/modifying an object write immediately, on an explicit save, on flush, or on commit?
  - Does querying mid-session trigger an autoflush of staged changes?
  - Is there an implicit transaction per request/session, and who commits it?
- Known traps to check for, not assume:
  - SQLAlchemy: `session.add()` stages; queries autoflush staged changes; nothing is durable until `commit()`. A "dry run" that queries but skips commit still flushed.
  - Django: attribute changes persist only on `.save()`, which by default writes *all* fields (use `update_fields=` to scope); outside `transaction.atomic()`, autocommit makes each save immediately permanent.
  - Active Record: callbacks/hooks on save can write additional rows you didn't ask for.
- For dry-run modes, don't rely on "I just won't commit": disable autoflush or use an explicitly rolled-back transaction, and say which mechanism you used.
- When data must be durable, end with an explicit commit (or document which framework layer commits). "The session probably commits on close" is a guess, and sessions that roll back on close are common.
- If unsure, write a two-line test: change, then read back through a *separate* connection. The second connection tells the truth.

**Red flags that you're about to violate this:**

- "add() saves the object, same as save() does..."
- "Nothing hits the database until commit, so this is a safe dry run..."
- "The session will commit when the request ends, it always does..."
- "save() only writes the field I changed..."
- "This is how the ORM I usually see does it..."

---

## Why It Works

1. **It outlaws cross-ORM pattern transfer.** The root cause is semantics imported from the wrong library; making "which ORM is this and what does it do" an explicit prerequisite blocks the transfer at the source.

2. **It reduces the problem to three answerable questions.** Write timing, autoflush, and transaction ownership cover nearly every variant of this bug, and each has a findable answer in docs or existing project code.

3. **It hardens dry runs structurally.** "Skip the commit" is the dry-run idea that autoflush quietly defeats; requiring rollback-or-noautoflush replaces a leaky convention with a real mechanism.

4. **It gives a ground-truth probe.** Reading back through a second connection bypasses every layer of ORM caching and staging, settling arguments the documentation reading didn't.

## Origin

A reconciliation script was given a `--dry-run` flag implemented as "do everything except `session.commit()`." It also logged progress by querying counts mid-loop, and each query autoflushed the staged updates. The dry run was run against production, twice, to validate the logic. Both runs wrote. The team discovered it when the "real" run reported zero rows needing changes, and spent the day working out which of three executions had produced the current state.
