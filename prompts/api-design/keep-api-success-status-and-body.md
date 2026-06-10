---
title: Keep API Success Status and Body Stable
slug: keep-api-success-status-and-body
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops 200-to-201 and 200-to-204 swaps that break clients checking exact codes"
---

# Keep API Success Status and Body Stable

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing a success response's status code or removing its body on an endpoint clients already parse.

**[Copy-paste ready version](../../install/keep-api-success-status-and-body.md)** — just the instruction block, no explanation.

## The Problem

The happy path gets broken politely. An AI assistant reviews a POST handler that returns `200` with the created object and upgrades it to `201 Created` — textbook REST. Or it notices a DELETE returning `200` with `{"deleted": true}` and trims it to a tidy `204 No Content`. Both changes are exactly what an API design lint would suggest, and both detonate in clients that were written against the old behavior.

Plenty of deployed code checks `status === 200`, not `response.ok`. A client that did `res.json()` on the DELETE response now throws on an empty 204 body. An integration that read the created object out of the POST response to get the new record's ID now gets the ID from a body that no longer exists, or from a `Location` header it never looked at. None of this fails in the repo's own tests, because the AI updated those too.

The assistant makes these edits because success responses look like free wins: the spec is unambiguous, the diff is small, and nothing visible objects. The clients that hard-coded `200` and the parsers that require a body are all outside its context window.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep API Success Status and Body Stable

NEVER change the success status code of an existing endpoint, and NEVER remove or empty a success response body that previously had content. Deployed clients check exact codes (`status === 200`) and unconditionally parse bodies; "more correct" codes like 201 or 204 break both.

- Do not upgrade `200` to `201` on creation endpoints, `200` to `202` for async work, or `200`-with-body to `204 No Content`, no matter how strongly REST convention recommends it.
- Removing a response body is a breaking change even when the body looks redundant. Clients call `.json()` on it, read IDs from it, and log it. An empty 204 body makes those parsers throw.
- The reverse also holds: do not start returning a body where none existed, if clients might treat unexpected content as an error — and never change `204` back to `200` on a shipped endpoint.
- New endpoints you create from scratch should use the correct codes from day one. The freeze applies to endpoints that have already shipped.
- If the user asks for the "correct" codes on an existing endpoint, make the change only after stating that any client checking exact status values or parsing the body will break, and offer to gate it behind a new API version.

**Red flags that you're about to violate this:**
- "This is a creation endpoint, so it should obviously return 201."
- "The response body just echoes the request — nobody needs it."
- "Returning 204 for DELETE is the standard; I'll align with it."
- "Any sane client checks the 2xx range, not the exact code."
- "I'm only touching the success path, which is the safe part."

---

## Why It Works

1. **It names the exact upgrades the AI reaches for** — 200→201, 200→204 — so the rule matches the moment of failure instead of staying abstract.
2. **It corrects a false belief about clients.** "Any sane client checks the 2xx range" is the rationalization; stating that deployed code checks exact values and parses bodies unconditionally replaces the imagined client with the real one.
3. **It covers the body, not just the code.** Most status-code rules miss that emptying a body is its own breaking change, which is the half the AI exploits.
4. **It channels correctness into new endpoints**, giving the AI a legitimate outlet for its REST knowledge instead of suppressing it.

## Origin

An assistant was asked to "bring the orders service in line with REST best practices." It changed the create-order endpoint from 200 to 201 and the cancel endpoint from 200-with-body to 204. The company's own kiosk app — maintained by a different team, in a different repo — checked `status == 200` and treated everything else as failure, so every order placed at a kiosk appeared to fail while actually succeeding. Customers re-submitted, and the duplicate orders took longer to clean up than the original change took to write.
