---
title: Python Aware Datetimes Only
slug: python-aware-datetimes-only
category: language-pitfalls
tags: [universal, python]
works_with: all
severity: critical
one_liner: "Stops timezone-naive datetime.now() from corrupting timestamps"
---

# Python Aware Datetimes Only

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents naive `datetime.now()` timestamps that mean different instants depending on where the code runs.

**[Copy-paste ready version](../../install/python-aware-datetimes-only.md)** — just the instruction block, no explanation.

## The Problem

`datetime.now()` returns a naive datetime: a wall-clock reading with no timezone attached. It means one thing on a developer laptop in Berlin and another on a UTC server, and Python will happily store, serialize, and compare these ambiguous values without complaint — right up until you compare a naive datetime with an aware one and get `TypeError: can't compare offset-naive and offset-aware datetimes`, usually in production, usually in a code path tests never exercised.

The classic AI-generated variant is `datetime.utcnow()`, which sounds safe and is arguably worse: it returns the correct UTC wall time *as a naive object*, so downstream code can't tell it's UTC. Serialize it with `.isoformat()` and you get a timestamp with no offset; a JS client then parses it as local time and every displayed time is wrong by the viewer's UTC offset. `utcnow()` is deprecated since Python 3.12 for exactly this reason, but it dominates training data.

Assistants reach for `datetime.now()` because it's the shortest spelling of "current time" and because mountains of tutorials use it. The damage is silent: shifted billing periods, expired tokens that aren't expired, audit logs that disagree with reality by exactly N hours.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Python Aware Datetimes Only

ALWAYS create timezone-aware datetimes in Python. NEVER use bare `datetime.now()` or `datetime.utcnow()` — both return naive objects that mean different instants on different machines and that cannot be safely compared, serialized, or converted.

- Right: `datetime.now(timezone.utc)` (from `datetime import datetime, timezone`) for "the current instant."
- Wrong: `datetime.utcnow()` — correct UTC value, but naive, so the UTC-ness is lost the moment it leaves the variable. It is deprecated; do not generate it even though training examples are full of it.
- Wrong: `datetime.fromtimestamp(ts)` — uses the server's local zone; use `datetime.fromtimestamp(ts, tz=timezone.utc)`.
- When parsing, attach the zone: `datetime.fromisoformat(s)` keeps an offset if the string has one; if the string is naive, you must decide and document what zone it represents — don't guess silently.
- Store and compute in UTC; convert to local time only at the display edge with `.astimezone(ZoneInfo("Europe/Berlin"))`.
- Naive datetimes are acceptable only for genuinely zone-free concepts (a recurring "9:00 AM" alarm, a date of birth) — leave a comment when you use one deliberately.
- Never mix: comparing or subtracting naive and aware datetimes raises `TypeError`. If you hit that error, fix the naive side; don't strip tzinfo from the aware side.

**Red flags that you're about to violate this:**

- "`datetime.now()` is the standard way to get the current time."
- "`utcnow()` is the safe version, that's what the name says."
- "The server runs in UTC anyway, so naive is effectively aware."
- "I'll strip tzinfo so the comparison stops raising TypeError."
- "Timezone handling is out of scope for this small helper."

---

## Why It Works

1. **It targets the trap inside the trap.** Most timezone guidance says "use UTC"; `utcnow()` *is* UTC and still wrong. Calling out the naive-but-UTC failure closes the loophole the model otherwise walks straight into.
2. **It bans the seductive quick fix.** Stripping tzinfo to silence `TypeError` converts a loud bug into a silent one; naming that move keeps the error pointing at the real problem.
3. **It defines the boundary.** "UTC internally, convert at the display edge" gives the model a placement rule, not just a prohibition, so it doesn't sprinkle conversions randomly.

## Origin

A subscription service computed period ends with `utcnow() + timedelta(days=30)` and stored the naive result. The billing reconciler, which used aware datetimes, crashed nightly with a comparison TypeError; someone "fixed" it by stripping tzinfo on the aware side. Customers in eastern timezones were then charged hours before their period ended, and the refund script took longer to write than the original feature.
