---
title: Don't Collapse Distinct Errors Into One Response
slug: dont-collapse-distinct-errors-into-one-response
category: error-handling
tags: [universal, errors, exceptions]
works_with: all
severity: high
one_liner: "AI handlers returning generic 500 for validation, auth, and outage alike"
---

# Don't Collapse Distinct Errors Into One Response

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents one catch-all from flattening five different failures into a single indistinguishable error.

**[Copy-paste ready version](../../install/dont-collapse-distinct-errors-into-one-response.md)** — just the instruction block, no explanation.

## The Problem

An AI-written request handler tends to end the same way: `except Exception as e: return jsonify({"error": "Internal server error"}), 500`. Inside that try block live at least five distinguishable failures — a malformed request body, a missing record, a permission violation, a downstream timeout, and an honest bug — and the handler renders all of them identically. The client retries things it shouldn't (the 400s), doesn't retry things it should (the transient 503-ish ones), and the API consumer files a bug report containing the only information they have: "it says internal server error."

This is the failure-mode sibling of catching a broad type: here the catch isn't just broad, it *maps everything to one outcome*. The same flattening appears outside HTTP — CLI tools that print "operation failed" and exit 1 for every distinct cause, RPC services that wrap all errors in `UNKNOWN`, GraphQL resolvers that bubble everything as a generic message.

Models do it because the catch-all-plus-500 is the universally compilable ending: it requires no inventory of what can actually fail inside the block. Enumerating failures takes analysis; flattening takes one clause. And superficially, the flattened handler "handles everything," which reads as thorough.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Collapse Distinct Errors Into One Response

Failures that mean different things to the caller MUST produce distinguishable outcomes. NEVER funnel validation errors, not-found, permission failures, and downstream outages into one generic catch-all response.

- In request handlers, map error categories before the catch-all: `except ValidationError: 400 with field details`, `except NotFound: 404`, `except PermissionDenied: 403`, `except UpstreamTimeout: 503 (retryable)` — then `except Exception: 500` for the truly unexpected
- The catch-all is for bugs only; if a known failure type is reaching it, that's a missing clause, not acceptable coverage
- Distinguishable means machine-distinguishable: different status codes / error codes (`{"error": {"code": "INVALID_EMAIL"}}`), not different prose in the same 500
- Never return 500 for a client mistake — the caller can fix a 400; a 500 tells them to wait and retry, which is exactly wrong for bad input
- Same rule beyond HTTP: CLIs should use distinct exit codes or distinct stderr messages per failure class; RPC handlers should use the protocol's status taxonomy (e.g. gRPC `INVALID_ARGUMENT` vs `UNAVAILABLE`), not `UNKNOWN` for everything
- Expected domain failures may carry detail to the caller; the generic 500 path should log full detail server-side but expose no internals (no stack traces or query text in responses)

**Red flags that you're about to violate this:**
- "One except clause at the bottom covers every case..."
- "It's all errors to the client anyway..."
- "Returning 500 for everything is simpler and safer..."
- "The client can read the message if they need specifics..."
- "I'll add granular handling later; generic works for now..."

---

## Why It Works

1. **It forces the failure inventory.** The flattening exists because nothing required the model to list what can go wrong inside the block. Mandating mapped clauses before the catch-all makes that enumeration the visible structure of the handler.

2. **It defines the catch-all's legitimate residue.** "Bugs only" turns the final clause from a coverage strategy into a tripwire — known failures arriving there become defects to fix instead of cases already handled.

3. **It anchors "different" in machine-readability.** Models will happily vary the message text and call it differentiated; requiring distinct codes/statuses targets what retry logic and client code actually consume.

4. **It states the retry contract that codes encode.** 400-vs-503 isn't pedantry — it's instructions to the caller about whether retrying can help; connecting codes to caller behavior gives the model a functional reason to classify.

## Origin

A mobile team integrated against an AI-generated backend endpoint that returned 500 for everything, including invalid input. Their client library, following standard practice, retried 500s with backoff — so every user who typo'd their email triggered five identical doomed requests, and the backend's error-rate alarms treated each typo as a quintuple server failure. Two teams investigated "instability" for a week. The endpoint was perfectly stable; it was just describing every event in its life, including user typos, as an internal server error.
