---
title: Version-Check Concurrent Updates
slug: version-check-concurrent-updates
category: concurrency
tags: [universal, concurrency, state]
works_with: all
severity: critical
one_liner: "Stops blind save-overwrites from silently discarding concurrent edits"
---

# Version-Check Concurrent Updates

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing read-edit-save flows that blindly overwrite the record, silently destroying whatever a concurrent editor changed in between.

**[Copy-paste ready version](../../install/version-check-concurrent-updates.md)** — just the instruction block, no explanation.

## The Problem

The standard AI-generated update endpoint: load the record, apply the user's changes to the object, save the whole object back. Between the load and the save — a gap that includes a network round trip to the user's browser and possibly their lunch break — someone else edits the same record. The second save writes the full object as *it* remembers it, and the first editor's changes vanish. No error, no conflict, no log line. The data is well-formed and wrong, which means the loss surfaces weeks later as "I definitely changed that" tickets that get closed as user error.

This is optimistic concurrency with the optimism and without the concurrency control. The AI omits the version check because the happy path doesn't need it: one editor, load-edit-save is perfect, and every CRUD tutorial it learned from has exactly one user. The conflict window feels theoretical right up until the record is popular — two support agents on the same ticket, two admins on the same product, a human and a background job on the same row.

The fix is one column and one WHERE clause: writes state which version of the world they were based on, and writes based on a stale version fail loudly instead of winning silently.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Version-Check Concurrent Updates

Every read-edit-save flow MUST carry a version: reads return it, writes assert it. A write based on stale data must fail visibly, never overwrite silently.

Blind last-write-wins means concurrent editors destroy each other's work with no error anywhere.

- Add a version (integer or timestamp) to mutable records. Update with `UPDATE t SET ..., version = version + 1 WHERE id = ? AND version = ?` and check rows-affected; zero rows means conflict, and conflict is a result to handle, not a row to assume.
- Thread the version through the full loop: API responses include it (field or ETag), edit forms carry it, save requests send it back, the server asserts it (`If-Match` for HTTP APIs). A version checked only server-side against a server-side read guards the wrong gap — the race is across the *user's* edit session.
- On conflict, do something honest: return 409/412 with the current state, let the caller re-fetch, re-apply, or merge. Never auto-retry by re-reading and re-saving the same payload — that's last-write-wins with extra steps.
- Partial updates reduce collisions but don't eliminate them: PATCHing one field still needs a version when the validity of the change depends on state the editor saw.
- Same rule outside databases: document stores (use the native CAS/sequence number), config files, object storage (conditional puts), in-memory stores (compare-and-set). Anywhere two writers can hold copies of one record.
- Background jobs editing records that humans also edit need versions most of all; the job won't file a ticket when its update evaporates.

**Red flags that you're about to violate this:**
- "Two people editing the same record at once basically never happens."
- "Last write wins is a reasonable default; the newest edit is probably right." (Newest *save*, not newest *information*.)
- "Adding version plumbing through the API is a lot of ceremony for a CRUD form."
- "We can add conflict handling later if users complain." (They can't tell what happened, so they won't complain — they'll just lose data.)
- "The ORM's save() handles concurrency." (Check. Most write all fields, unconditionally.)

---

## Why It Works

1. **It converts silent loss into a visible, handleable event** — the rows-affected check is the moment a race stops being undetectable, which is the entire battle; everything after a 409 is ordinary product design.
2. **End-to-end version threading guards the real window** (the user's open edit form), where server-only checks guard microseconds and miss the minutes.
3. **One column plus one WHERE clause is cheap enough to be a default,** which matters: rules that demand heavy machinery get skipped on exactly the boring CRUD endpoints where this bug lives.
4. **It forbids the fake fix** (auto re-read-and-retry with the same payload), which passes every conflict test while preserving the data loss.

## Origin

Two ops engineers worked the same incident runbook page during an outage; both loaded it, both edited different sections, both saved. The second save erased the first engineer's updated escalation contacts — silently, mid-incident — and the on-call paged a number that had been corrected an hour earlier. The wiki had revision history, so the data was recoverable; the endpoint just never checked it. One `WHERE version = ?` and a conflict banner later, the same collision became a thirty-second merge instead of a wrong page at the worst time.
