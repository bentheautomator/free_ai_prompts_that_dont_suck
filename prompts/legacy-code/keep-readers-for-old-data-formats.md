---
title: Keep Readers for Old Data Formats
slug: keep-readers-for-old-data-formats
category: legacy-code
tags: [universal, legacy, data]
works_with: all
severity: critical
one_liner: "Keeps parsers for old formats alive while old records still use them"
---

# Keep Readers for Old Data Formats

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from cleaning up handling for "legacy" data formats while records in that format still sit in the database, the archive, and customers' filesystems.

**[Copy-paste ready version](../../install/keep-readers-for-old-data-formats.md)** — just the instruction block, no explanation.

## The Problem

Code can be migrated in one deploy. Data cannot. When a system moves from format v1 to v2, the writer switches over immediately — but every v1 record ever written is still out there: rows serialized years ago, archived exports, backup snapshots, documents saved on customer machines, messages parked in dead-letter queues. The v1 *reader* has to live for as long as any v1 *data* lives, which is usually somewhere between "years" and "forever."

AI assistants miss this because they reason about code reachability, not data demographics. The v1 parsing branch looks vestigial: nothing writes v1 anymore, the format constant is marked legacy, the branch rarely shows up in traces. So the assistant deletes it, or "simplifies" the migration-on-read logic, or drops the version field check. Everything works — until a user opens a document from 2019, a restore pulls a pre-migration backup, or a quarterly job touches the cold partition where the old rows live. Then the system meets its own history and can't read it.

These failures are slow-fuse and high-stakes: the data that breaks is old, which means it's the data someone needs for an audit, a dispute, or a recovery — the worst possible moments to discover it's unreadable.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Readers for Old Data Formats

NEVER remove or simplify code that reads an old data format because nothing writes that format anymore. Writers follow the code; readers follow the data, and old data outlives old code by years. A v1 reader is dead only when the last v1 record is dead.

Before touching format-handling, deserialization, or migration-on-read code:

- Ask the data question, not the code question: do records in this format still exist anywhere — live tables, cold storage, archives, backups, dead-letter queues, files on customer devices? If you can't verify, the reader stays.
- Distinguish writers from readers explicitly. Retiring a writer is routine; retiring a reader requires evidence that the format is extinct in all storage, including storage outside your reach (anything customers downloaded is forever).
- Check backup and restore paths. Data restored from a snapshot predates every migration that ran after the snapshot; the reader is the only thing standing between a restore and a corruption.
- Treat "lazy migration" code (upgrade-on-read) as load-bearing until the migration is verified complete — meaning someone confirmed zero unmigrated records, not "the migration job ran."
- If asked to remove a legacy format path, propose the safe sequence: measure remaining records, backfill-migrate them, verify zero, then remove the reader. Removal is the last step, never the first.

**Red flags that you're about to violate this:**
- "Nothing has written this format in four years."
- "The migration ran ages ago, all the data is converted."
- "This version check never matches anymore."
- "Old backups don't count, we'd never restore something that old."
- "Files customers downloaded aren't our problem to keep reading."
- "I'll simplify the deserializer to handle only the current format."

---

## Why It Works

1. **It swaps the reachability question for the demographics question.** "Is this branch reached?" lets old data hide; "does data in this format exist anywhere?" puts archives, backups, and customer disks back into the analysis.
2. **The writer/reader asymmetry is the load-bearing concept.** Once stated, it's obvious — and it converts "this format is legacy" from a deletion argument into a reader-retention argument.
3. **The backup clause covers time travel.** Restores resurrect pre-migration data by design; remembering this single path defeats the most common "all data is migrated" fallacy.
4. **The measure-migrate-verify-remove sequence gives cleanup a legitimate route,** so format readers don't accumulate forever — they get removed when the data is actually gone, with evidence.

## Origin

A document service stored attachments with a v1 envelope until a 2018 format change; an upgrade-on-read shim converted old envelopes whenever touched. Years later, an assistant streamlining the read path removed the shim — the version byte "never varied" in any recent sample it checked, because hot data was all v2. Cold data wasn't. The failure surfaced when a customer in a legal dispute exported their 2017 archive and received a zip of unreadable blobs. The shim was restored from history, but the incident review's first line was the lasting part: the records were fine the whole time; we deleted our only ability to read them.
