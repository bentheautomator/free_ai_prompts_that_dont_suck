---
title: Freeze API Default Query Behavior
slug: freeze-api-default-query-behavior
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops changing what an endpoint returns when callers pass no parameters"
---

# Freeze API Default Query Behavior

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing what an existing endpoint does when callers omit a parameter — new default filters, flipped flags, narrowed scopes.

**[Copy-paste ready version](../../install/freeze-api-default-query-behavior.md)** — just the instruction block, no explanation.

## The Problem

The most invisible API contract is what happens when the caller sends nothing. `GET /orders` returns all orders; the AI, adding an `include_archived` flag, decides the sensible default is `false` — and every existing caller, who by definition passes no flag, silently loses their archived orders. Or it adds a `status` filter and defaults it to `active`, or scopes a list endpoint to the current user "for safety," or flips an existing default from `include_deleted=true` to `false` because the old default "was clearly wrong."

No caller gets an error. The response shape is identical, the status is 200, and the data is simply *less* than it used to be — or different. Sync jobs miss records and report success. Dashboards undercount. The clients most affected are the oldest and least maintained, exactly the ones nobody is watching.

This happens because when an AI adds a parameter, it has to pick a default, and it picks the one that makes the *new feature* sensible rather than the one that preserves the old behavior. From inside the diff, `include_archived=false` looks conservative. From outside, it's a filter applied retroactively to every caller in the world.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Freeze API Default Query Behavior

NEVER change what an existing endpoint returns when a parameter is omitted. The no-parameter request is its own contract: every existing caller sends it, and a new or changed default rewrites all of their results at once without a single error.

- When adding a new filter, flag, or scope parameter to an existing endpoint, its default MUST reproduce the endpoint's current behavior exactly — even when that default looks wrong. If the endpoint returned archived rows before, `include_archived` defaults to `true`.
- Never flip an existing default (`include_deleted`, `expand`, `status`, default date ranges) on a shipped endpoint, and never narrow an endpoint's implicit scope (all records → current user's records) outside an explicit, user-approved breaking change.
- A request with no params returning a 200 is not evidence of compatibility. The contract is the *content*: same records, same scope, same filters as before the change.
- If the current default is genuinely dangerous or wrong, present the fix as a breaking change: new API version, new endpoint, or a deprecation window with announced default-flip date. Not a silent edit.
- After adding any parameter, state in your summary what a parameter-less request returned before and after. They must match.

**Red flags that you're about to violate this:**
- "Excluding archived items by default is what most callers would expect."
- "The old default was a footgun; defaulting to the safe value fixes it."
- "Callers who want the old behavior can just pass the flag."
- "I'm only adding a parameter — omitting it is handled gracefully."
- "Scoping the list to the current user is more secure, so it's an improvement."

---

## Why It Works

1. **It gives the no-parameter request contract status.** The AI thinks in terms of parameters it's adding; declaring the empty query string a shipped interface makes "what does omission do?" a compatibility question instead of a design choice.
2. **It pins the default to historical behavior, not sensibleness** — directly countering the AI's habit of choosing the default that flatters the new feature.
3. **It pre-rebuts "callers can pass the flag,"** the rationalization that ignores the defining property of existing callers: they were written before the flag existed.
4. **It demands a before/after statement for parameter-less requests**, making the silent change impossible to make silently.

## Origin

Adding an `environment` filter to a `/deployments` endpoint, an assistant defaulted it to `production` on the theory that production is what people usually mean. The internal release dashboard — a separate repo, no parameters — stopped showing staging deployments, and a release manager spent a morning convinced staging deploys were failing when they were merely filtered. Cheap as incidents go, but it burned a morning across three teams and ended with the default reverted to "all," where it had always effectively been.
