---
title: Never Check Then Act
slug: never-check-then-act
category: concurrency
tags: [universal, concurrency, races]
works_with: all
severity: critical
one_liner: "Stops TOCTOU races where the world changes between the check and the act"
---

# Never Check Then Act

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing "check a condition, then act on it" sequences that two concurrent callers can interleave, producing duplicate records, overdrawn balances, and clobbered files.

**[Copy-paste ready version](../../install/never-check-then-act.md)** — just the instruction block, no explanation.

## The Problem

The most natural code in the world is `if (!exists(x)) create(x)` or `if (balance >= amount) deduct(amount)`. It reads like a guarantee. It isn't one. Between the check and the act, another request runs the same check, gets the same answer, and acts too. Two users both pass the balance check; the account goes negative. Two requests both see "no user with this email"; you now have two. The window is microseconds wide, which means it never fires on your laptop and fires every day at production traffic.

AI assistants write check-then-act by default because the failure is invisible in a single-threaded mental model: read the code top to bottom and it is airtight. Every unit test passes, because tests run one request at a time. The bug only exists in the gap between two lines, and no amount of staring at one execution reveals it.

The fix is never "check more carefully." It's to stop separating the check from the act: make one atomic operation that checks and acts in a single step, enforced by something that actually serializes concurrent callers — the database, the filesystem, an atomic primitive.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Check Then Act

NEVER write code that checks a condition and then acts on it as two separate steps when concurrent callers could interleave between them. The check is stale the instant it returns. Replace the check-then-act pair with a single atomic operation and handle its failure.

- Don't check existence then create: `if not exists: insert` → use a unique constraint plus insert-and-catch-conflict, or an upsert (`INSERT ... ON CONFLICT`, `putIfAbsent`, `setdefault`).
- Don't check a file then open it: `if (!fs.existsSync(p)) fs.writeFileSync(p)` → open with exclusive-create flags (`'wx'`, `O_CREAT|O_EXCL`) and handle `EEXIST`.
- Don't check a balance/quota/inventory then deduct: read-check-write → a conditional atomic write: `UPDATE account SET balance = balance - :amt WHERE id = :id AND balance >= :amt`, then check rows affected.
- Don't check "is this slot free" then claim it (usernames, seats, locks, job leases). Claim it atomically and treat rejection as the normal path, not an error.
- When no atomic primitive exists, hold a lock around both the check and the act — the same lock for every code path that touches that state.
- Treat the conflict outcome as expected control flow: catch it, report it cleanly, retry where appropriate. "It would have already failed the check" is not a reason to skip handling it.

**Red flags that you're about to violate this:**
- "I already checked that it doesn't exist two lines up."
- "This endpoint won't get concurrent calls for the same user."
- "The window between check and act is tiny."
- "I'll validate in the app layer; the database doesn't need a constraint."
- "Adding conflict handling complicates the happy path."

---

## Why It Works

1. **It names the gap as the bug.** The AI's review pass looks for wrong logic; this rule makes "two correct lines with a gap between them" a recognizable defect shape.
2. **It redirects to primitives that actually serialize** — constraints, atomic compare-and-write, exclusive-create flags — instead of "being careful," which no amount of careful single-threaded reasoning can deliver.
3. **It reframes conflicts as normal control flow,** so the AI writes the `ON CONFLICT` / `EEXIST` handler instead of assuming the guard made it unreachable.
4. **Tests can't save you here and the rule says so:** sequential tests exercise exactly zero interleavings, so passing tests are not evidence against this bug.

## Origin

A signup flow checked `SELECT count(*) FROM users WHERE email = ?` before inserting, and the table had no unique index because "the app already validates." A marketing email with a signup link went out, people double-clicked, and the support queue filled with accounts that half-existed twice — password resets landed on one row, subscriptions on the other. Deduplicating took longer than the feature took to build.
