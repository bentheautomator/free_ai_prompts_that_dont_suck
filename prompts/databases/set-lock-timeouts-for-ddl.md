---
title: Set Lock Timeouts for DDL
slug: set-lock-timeouts-for-ddl
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: high
one_liner: "DDL that queues behind a long query and blocks the whole table with it"
---

# Set Lock Timeouts for DDL

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents a fast ALTER TABLE from waiting behind one slow query while everything else queues behind the ALTER.

**[Copy-paste ready version](../../install/set-lock-timeouts-for-ddl.md)** — just the instruction block, no explanation.

## The Problem

Here's the outage that confuses everyone afterward: the migration was a metadata-only change, genuinely instant, and it still took the site down. The mechanism is lock queueing. `ALTER TABLE orders ADD COLUMN note text;` needs an ACCESS EXCLUSIVE lock for a millisecond, but it must *acquire* it first, and a long-running report query currently holds a conflicting lock on `orders`. So the ALTER waits. The cruelty is what happens behind it: every new query on the table, including plain SELECTs, queues behind the *waiting* ALTER, because lock acquisition is fair-ordered. One slow report plus one instant migration equals a frozen table for as long as the report runs.

AI assistants never guard against this because the migration itself is innocent; analyzed in isolation, it's a millisecond of work. The danger isn't in the statement but in the queue it joins, and the AI doesn't model lock queues. It also doesn't know your workload has a 20-minute analytics query at exactly the hour deploys happen, but it can write the migration so that fact can't cause an outage.

The guard is two settings: a lock timeout, so the ALTER gives up quickly instead of blockading the table, and retry logic, so giving up means trying again rather than failing the deploy.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Set Lock Timeouts for DDL

ALWAYS set a lock timeout before running DDL against a table with live traffic. A waiting ALTER blockades the table: every query issued after it queues behind it, so one long-running query plus your "instant" migration equals an outage that lasts as long as that query.

- Postgres, at the top of any migration touching a busy table:
  `SET lock_timeout = '5s';`
  The ALTER now fails fast if it can't get the lock, instead of freezing the table while it waits. Pair with `SET statement_timeout` for the DDL's own runtime where appropriate.
- Failing fast requires a retry plan: re-run the migration (manually or with backoff). A migration that occasionally needs a second attempt is healthy; one that can blockade prod is not. Many teams wrap this pattern in helpers or use libraries that do timed-retry DDL; use what the project has.
- MySQL: set `lock_wait_timeout` for the session; the same queueing dynamic applies to metadata locks (a forgotten open transaction can hold an MDL that blocks the ALTER, and the ALTER blocks the world).
- Before heavy DDL, check for long-running queries/transactions on the target table (`pg_stat_activity`) and say what you found; deploying DDL into a known 30-minute query is a choice, not luck.
- This complements, not replaces, choosing non-locking forms (`CREATE INDEX CONCURRENTLY`, metadata-only ALTERs). The timeout protects the acquisition; the right DDL form protects the hold.
- Local and CI databases have no contention, so this failure is invisible everywhere except production. Don't conclude safety from quiet environments.

**Red flags that you're about to violate this:**

- "This ALTER is metadata-only, it takes a millisecond..."
- "Lock timeouts are an ops concern, not a migration concern..."
- "If something's holding a lock, the ALTER will just wait politely..."
- "It applied instantly in staging..."
- "Adding retry logic for a one-line migration is over-engineering..."

---

## Why It Works

1. **It teaches the queue, not the statement.** The AI's safety analysis stops at "this DDL is fast"; explaining that *waiting* DDL blocks all subsequent queries relocates the risk to where it actually lives.

2. **It pairs the timeout with retries.** A lock timeout alone converts outages into failed deploys, which teams then "fix" by removing the timeout; making retry part of the pattern keeps the guard in place.

3. **It corrects the "waiting is polite" intuition.** The AI assumes blocked means harmlessly paused; fair-ordered lock queues make blocked mean blockading, and stating that flips the default from wait to fail-fast.

4. **It explains why no test ever catches this.** Contention requires concurrency that dev, CI, and staging don't have; pre-empting "it was instant in staging" removes the false reassurance.

## Origin

A one-column ALTER was deployed at 9:00 a.m., the same minute a scheduled finance export began its long scan of the same table. The ALTER waited 22 minutes for its lock; every query on the company's busiest table queued behind it within seconds, and the application was effectively down until someone killed the export. The migration, when it finally ran, took 4 milliseconds. A five-second lock timeout and one retry would have made the whole event a log line.
