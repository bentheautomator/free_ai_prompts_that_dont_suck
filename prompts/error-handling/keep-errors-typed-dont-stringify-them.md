---
title: Keep Errors Typed, Don't Stringify Them
slug: keep-errors-typed-dont-stringify-them
category: error-handling
tags: [universal, errors, exceptions]
works_with: all
severity: high
one_liner: "AI flattening typed errors into strings that callers must parse to react"
---

# Keep Errors Typed, Don't Stringify Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents rich, matchable error objects from being flattened into prose that callers have to grep.

**[Copy-paste ready version](../../install/keep-errors-typed-dont-stringify-them.md)** — just the instruction block, no explanation.

## The Problem

A function catches a `UniqueViolationError` and returns `{"success": False, "error": str(e)}`. The caller now holds the string `'duplicate key value violates unique constraint "users_email_key"'` and nothing else. To distinguish "email taken" from "database down," the caller must do `if "duplicate key" in error:` — string matching against a message that the database driver may reword in its next release. The error's type, its fields (`constraint_name`, `status_code`, `retryable`), and its identity as a catchable class are all gone, melted into prose at the first catch site.

AI assistants do this at every boundary they create: catch blocks that `return str(e)`, API handlers that put `e.message` in a JSON body and discard `e.code`, Result-style returns where the error channel is `string`. Strings cross every boundary without ceremony — no exception types to import, no serialization questions — so the model reaches for them whenever it converts an exception into a return value.

The cost compounds. Once one layer stringifies, every layer above it is doing forensic text analysis. Behavior starts depending on message wording, which means a harmless message improvement in a dependency silently breaks your error handling.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Errors Typed, Don't Stringify Them

NEVER reduce an error to its message string when passing it to code that may need to react to it. Callers branch on types and codes; strings are for humans at the end of the line.

`str(e)` keeps the prose and throws away everything programmable: the class, the error code, the structured fields, the cause chain.

- When converting an exception into a return value, return the exception object or a structured error (type/code + fields), not `str(e)`: `return Err(e)` or `{"error": {"code": "EMAIL_TAKEN", "field": "email"}}` — never `{"error": str(e)}`
- Never write code that branches on message text — `if "duplicate key" in str(e)` or `e.message.includes("timeout")` — branch on the exception class, `e.code`, `errno`, or HTTP status instead
- In Result/Either-style code, the error channel's type should be an error type or union of them, not `string`
- At API boundaries, serialize errors as structured data: a stable machine-readable `code` plus a human `message` — clients must be able to react to the code without parsing the message
- Stringify only at terminal sinks: log formatting, console output, UI display — places where no further code will make decisions based on the error
- If a third-party library forces you to receive strings, convert them to typed errors at that boundary once, instead of letting strings spread inward

**Red flags that you're about to violate this:**
- "I'll just return the error message so the caller knows what happened..."
- "Checking if the message contains 'not found' handles that case..."
- "A string error field keeps the response shape simple..."
- "str(e) captures everything important..."
- "The caller only needs to display it anyway..."

---

## Why It Works

1. **It draws the line at "code that may react."** The model can't tell display contexts from decision contexts, so it stringifies everywhere. Defining terminal sinks (logs, UI) as the only legal stringify points makes the boundary checkable.

2. **It names the fragile artifact directly.** `if "duplicate key" in str(e)` is the smoking gun this rule exists for; showing the exact pattern lets the model recognize it in its own output before emitting it.

3. **It exposes what `str(e)` deletes.** The model believes the message *is* the error. Enumerating the lost goods — class, code, fields, cause chain — corrects the mental model that makes stringifying feel lossless.

4. **It provides the boundary-conversion escape valve.** Some inputs really are strings; "convert to typed once at the edge" handles that case without licensing string errors internally.

## Origin

A payments wrapper written by an assistant caught the processor SDK's typed exceptions and returned `{"ok": false, "error": str(e)}`. Application code grew a dozen `in` checks against those strings — including `"card_declined" in error` to decide whether to prompt the user for a different card. An SDK minor version reworded its messages; declines started falling through to the generic "try again later" path, and retry-able network failures were shown as declines. The team spent two days hunting a "payments bug" that was actually twelve string comparisons rotting at once.
