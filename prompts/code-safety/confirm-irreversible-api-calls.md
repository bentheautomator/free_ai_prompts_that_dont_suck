---
title: Confirm Irreversible API Calls Before Making Them
slug: confirm-irreversible-api-calls
category: code-safety
tags: [universal, api, production]
works_with: all
severity: critical
one_liner: "AI calling delete endpoints on live services while exploring or testing"
---

# Confirm Irreversible API Calls Before Making Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from invoking delete, cancel, revoke, or purge endpoints against live services as casually as it calls GET.

**[Copy-paste ready version](../../install/confirm-irreversible-api-calls.md)** — just the instruction block, no explanation.

## The Problem

While "verifying the integration works," the AI calls the delete endpoint — because deleting the test object it just created seemed like polite cleanup, except the ID variable held a real object's ID from an earlier listing call. Or it's exploring an SDK and runs `client.projects.delete(project_id)` to see what the response shape looks like. Or it cleans up "orphaned" cloud resources whose orphan-ness it determined by name. API calls all look the same in code: same client, same one-liner shape, same await. `GET /users` and `DELETE /users` differ by one word and one unrecoverable customer record.

What makes this worse than local file damage is that API deletions often cascade server-side — deleting a project takes its data, its webhooks, its access grants — and there's no trash can on the other end of an HTTP call. Many services hard-delete immediately. The AI treats the API client as a sandbox because it's "just making calls from a script," but the service on the other end is real, live, and doing exactly what it's told.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Confirm Irreversible API Calls Before Making Them

NEVER call a destructive API endpoint — delete, cancel, revoke, purge, archive, deactivate — against a live service without explicit user confirmation for that specific call. An HTTP request has no undo, and many services hard-delete with cascades.

The core problem: destructive API calls look identical to safe ones in code, so the caution that applies to `rm -rf` doesn't fire for `client.resources.delete(id)`. The service on the other end is real even when your script feels like a sandbox.

- Treat the verbs as a class: anything named delete/destroy/remove/cancel/revoke/purge/terminate, and any HTTP DELETE, requires confirmation before execution against a non-sandbox target.
- Before such a call, state: the exact resource (ID *and* human-readable name fetched fresh via a read call), what cascades with it, and whether the service offers recovery (soft delete, retention window) — or "none."
- Never delete objects to "clean up after testing" unless you created them in this session and verified the ID you hold is the one you created — not one picked up from a list call.
- Exploring an API or SDK means read-only endpoints. You never learn a delete endpoint's response shape by calling it on real data; read the docs instead.
- Don't determine deletability by name or appearance ("looks orphaned", "seems like a test object"). Names lie; `test-final` is somebody's production.
- Loops multiply everything: a confirmed single delete is not a confirmed bulk delete. Re-confirm anything iterating destructive calls.

**Red flags that you're about to violate this:**
- "I'll clean up the objects I made — this ID should be mine..."
- "Let me hit the delete endpoint to check the integration works both ways..."
- "These resources look orphaned, nobody will miss them..."
- "It's called from a test script, so it's basically a test environment..."
- "The API probably soft-deletes anyway..."

---

## Why It Works

1. **It transfers shell-command caution to HTTP.** The AI already has guardrails around `rm`; defining the destructive-verb class extends that reflex to API clients, where the syntax gives no danger signal.

2. **It requires a fresh read before the write.** Fetching the resource's name and contents before deleting catches the stale-ID and wrong-variable cases — the most common mechanical cause of wrong-target deletions.

3. **It forces the recovery question.** Having to state "soft delete or none" makes the AI confront irreversibility explicitly; "none" in its own output is a powerful brake.

## Origin

An assistant wiring up a cloud storage SDK wrote a smoke test that created a bucket, uploaded a file, and deleted the bucket. The bucket-name variable defaulted to a value from the team's shared config when the create call failed — which it did, due to a naming collision with the existing production bucket. The delete call then succeeded against precisely that bucket. The service deleted it, contents and all, with the API equivalent of a shrug.
