---
title: Distinguish Missing From Failed Lookups
slug: distinguish-missing-from-failed-lookups
category: error-handling
tags: [universal, errors]
works_with: all
severity: critical
one_liner: "AI treating 'lookup failed' and 'thing does not exist' as the same outcome"
---

# Distinguish Missing From Failed Lookups

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents "the database is down" from being processed as "this record doesn't exist."

**[Copy-paste ready version](../../install/distinguish-missing-from-failed-lookups.md)** — just the instruction block, no explanation.

## The Problem

Here's a function an AI will happily write: `def get_user(id): try: return db.fetch_user(id) except Exception: return None`. The caller checks `if user is None:` and treats it as "no such user" — maybe creating a duplicate account, denying a login, or kicking off deletion of "orphaned" data. But that None has two meanings welded together: *the user does not exist* (a fact about the world) and *I couldn't find out* (a fact about the infrastructure). During a database hiccup, every user temporarily "doesn't exist."

These two outcomes demand opposite responses. Absence is an answer — act on it. Failure is a non-answer — retry, propagate, or refuse to proceed. Code that conflates them takes confident action on information it doesn't have. The nastiest instances are in authorization (`get_permissions` failing → empty permissions → access denied, or worse, a `has_blocklist_entry` check failing → "not on blocklist" → access granted) and in reconciliation jobs (fetch fails → "records gone upstream" → delete local copies).

AI assistants create the conflation in both directions: catching connection errors and returning the not-found sentinel, or — equally bad — taking an API's 404 and retrying it like an outage. The type system rarely objects, because `None`/`null` happily represents both meanings.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Distinguish Missing From Failed Lookups

"It doesn't exist" and "I couldn't check" are different outcomes and must stay different all the way up the stack. NEVER catch an infrastructure error and return the not-found value.

Absence is an answer you may act on. Failure is the absence of an answer — acting on it means acting on nothing.

- `except ConnectionError: return None` in a lookup function is forbidden; let infrastructure errors raise, return None only for genuine absence
- Keep the distinction in return shapes: absence → `None`/empty/`NotFound`; failure → exception or error result. If a function can produce both, the types must differ — never the same sentinel
- In HTTP clients: 404 means absent (act accordingly, don't retry); 5xx/timeout means unknown (retry or propagate, never treat as absent)
- Cache lookups: a cache *miss* means "go compute"; a cache *connection failure* should be handled as an explicit degrade decision, not silently folded into miss-and-recompute without a decision that the backend can take the load
- Be paranoid wherever absence triggers action — account creation, access control, deletion, reconciliation: before acting on "not found," confirm the code path can only reach that branch via a successful lookup
- Deny-by-default security checks must distinguish too: "permission check errored" should fail the request loudly, not quietly evaluate as "no permissions" (or worse, "no restrictions")

**Red flags that you're about to violate this:**
- "If the fetch fails, None is the safe thing to return..."
- "Either way, we don't have the user, so it's the same case..."
- "The caller already handles None, so I'll reuse that path..."
- "A failed check means they don't have access, which is safe..."
- "If the upstream call errors we can treat it as no data..."

---

## Why It Works

1. **It gives the two Nones different epistemic status.** "An answer" versus "absence of an answer" is the distinction the model's sentinel-collapsing erases; once named, `except: return None` visibly converts ignorance into a fact.

2. **It flags the high-blast-radius branches.** Creation, deletion, and access control are where conflation turns into incidents; telling the model to audit specifically those branches focuses the rule where it pays.

3. **It corrects both directions.** Models also retry 404s and treat misses as outages; covering failure-as-absence *and* absence-as-failure stops the fix for one from causing the other.

4. **It dismantles the "deny is always safe" shortcut.** Failing closed on *errors* still needs to be loud — quiet denial during an outage locks out every user with no alert; distinguishing errored-check from negative-check preserves both security and observability.

## Origin

A sync service reconciled local records against a partner API nightly: anything the API didn't return got archived locally as "removed upstream." An assistant's error handling caught request timeouts and returned an empty result set — indistinguishable from "partner has no records." The first night the partner API had a slow patch, the job archived 60,000 perfectly valid records as gone. Restore took a weekend, and the postmortem's root cause was one catch block that turned "couldn't ask" into "asked, and the answer was nothing."
