---
title: Never Rename Serialized Fields
slug: never-rename-serialized-fields
category: refactoring
tags: [universal, refactoring, serialization]
works_with: all
severity: critical
one_liner: "Stops renames of fields that live in JSON, databases, queues, or caches"
---

# Never Rename Serialized Fields

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from renaming struct or class fields whose names are written into wire formats, stored documents, queue messages, or cache entries.

**[Copy-paste ready version](../../install/never-rename-serialized-fields.md)** — just the instruction block, no explanation.

## The Problem

Some field names are just names. Others are data. When a class gets serialized to JSON, persisted to a document store, pushed onto a queue, or stashed in a cache, its field names escape the codebase and become part of every byte already written. Rename `usrId` to `userId` on a class like that and the rename compiles perfectly, every in-repo reference updates cleanly, and the type checker beams with approval. Then the service tries to read a message serialized last week, finds no `userId` in it, and either crashes or, far worse, quietly fills the field with `null` and keeps going.

AI assistants love these renames because abbreviated and inconsistent field names are exactly what "clean up this code" seems to be asking about. The model sees an ugly identifier; it cannot see the four million stored documents that spell it the old way. The compiler can't see them either, which is why this failure mode survives every static check and lands directly in production.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Rename Serialized Fields

NEVER rename a field, property, or enum value on any type that is serialized: to JSON or XML APIs, message queues, document databases, caches, config files, cookies, localStorage, or disk. Those names exist in data you do not control, and the rename orphans every byte already written.

The compiler verifies code against code. Nothing verifies code against stored data; that's your job.

- Before renaming any field, check whether its type flows through serialization: `json.dumps`/`JSON.stringify`, ORM/ODM mappings, protobuf/Avro/Thrift definitions, queue publishers, cache writes, API response builders. If yes, the in-data name is frozen.
- The safe pattern is rename-with-mapping: change the code-level name and pin the serialized name explicitly (`@JsonProperty("usrId")`, `serde rename`, `Field(alias=...)`, ORM `column_name=`). Code gets cleaner; bytes stay compatible.
- Enum values stored in databases or messages are field names' evil twin: renaming `PENDING_REVIEW` breaks every row holding the old string. Same rule, same mapping fix.
- Don't reorder or renumber fields in positional formats (protobuf tags, tuple-based encodings). Position is name.
- Dict keys used as message or cache schemas count, even with no class in sight. `event["usr_id"]` is a wire contract.
- If a true wire-format migration is wanted, that's a project with dual-read/dual-write phases, not a refactor. Propose it separately; never do it inline.

**Red flags that you're about to violate this:**

- "I'll make these field names consistent with the style guide."
- "The rename is safe; the compiler found every usage."
- "This DTO is internal, it just mirrors the API model."
- "Old messages will have drained from the queue by now."
- "Deserialization is lenient, missing fields just default."

---

## Why It Works

1. **It splits one name into two.** The model conflates the code-level identifier with the serialized key; the mapping pattern teaches that they're separable, so the cleanup urge gets satisfied without touching the bytes.
2. **"The compiler verifies code against code" preempts the strongest false assurance.** A clean build is precisely the evidence the model cites before this failure, and the rule discredits it in advance.
3. **The serialization checklist makes the invisible visible.** Queues, caches, cookies, and enum columns are where stored names hide; enumerating them turns "is this serialized?" into a concrete search instead of a guess.

## Origin

A cleanup pass renamed `del_flag` to `isDeleted` across a codebase, assistant-driven, compiler-approved. The class was the payload schema for a queue with a six-hour backlog. Every message published before the deploy deserialized with `isDeleted` defaulting to `false`, including the deletion events, which were silently processed as updates. Restoring consistency took a weekend of replaying events against a database snapshot.
