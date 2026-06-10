---
title: Never Enforce Authorization Only in the Frontend
slug: no-client-side-only-authorization
category: security
tags: [universal, security, auth]
works_with: all
severity: critical
one_liner: "AI hiding admin UI while leaving the admin API open to everyone"
---

# Never Enforce Authorization Only in the Frontend

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from implementing access control as UI visibility while the API trusts everyone.

**[Copy-paste ready version](../../install/no-client-side-only-authorization.md)** — just the instruction block, no explanation.

## The Problem

"Only admins should be able to delete users." The AI implements this faithfully — in React: `{user.isAdmin && <DeleteButton />}`, a route guard that redirects non-admins away from `/admin`, maybe a disabled state on the button. The UI is airtight. The `DELETE /api/users/:id` endpoint behind it checks only that *some* valid session exists, because the AI considered the frontend check to be "the" check. Anyone who opens devtools and replays the request with their own cookie can delete users; the entire control is a suggestion rendered in JavaScript.

This split happens naturally when work is divided by layer: the visible, demoable part of "restrict this to admins" is the UI part, so that's where the AI's attention lands, and the demo confirms success — the button really is gone for non-admins. Variants include role checks read from localStorage or an editable JWT payload client-side, feature gating that only hides nav links, pricing/quota logic enforced in the form, and mobile apps assumed to be "compiled, so users can't see the API" (they can, it's one proxy away).

The frontend check is fine — as UX. The load-bearing copy of every authorization rule lives server-side, on the endpoint, where the attacker can't edit it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Enforce Authorization Only in the Frontend

NEVER treat a client-side check as access control. Every authorization rule must be enforced on the server at the endpoint that performs the action; the frontend version is UX, not security.

Anything running on the user's device is under the user's control: hidden buttons, route guards, disabled states, and localStorage roles are all editable with devtools or replaced entirely by curl.

- When asked to restrict a capability "to admins" (or any role/plan/permission), implement the server-side check on the API endpoint first, then mirror it in the UI. If you only have time for one, it's the server one.
- The server check belongs on the action endpoint itself (middleware or in-handler), not just on the page route that links to it. APIs are called directly.
- Never determine privileges from client-supplied data: a role field in the request body, a flag in localStorage, or an unverified JWT claim. Read the role from the verified session/token server-side.
- Hiding is not removing: a feature-flagged admin panel whose endpoints respond to everyone is an open admin panel. Audit the endpoints, not the navigation.
- Don't trust the client for derived values either: prices, quotas, discounts, and permissions arrive from the client as suggestions; recompute them server-side.
- When completing any "restrict access" task, verify by describing (or writing) the failing case: a direct API request from a non-privileged session must get 403. If you can't show that, the task isn't done.

**Red flags that you're about to violate this:**
- "The button doesn't render for non-admins, so they can't trigger it..."
- "The route guard redirects them before they ever reach the page..."
- "Users won't know this endpoint exists, it's not in the UI..."
- "It's a compiled mobile app, the API isn't visible to users..."
- "The role is right there in the JWT payload, I'll read it client-side..."
- "Server-side checks can come in a follow-up, the demo needs the UI today..."

---

## Why It Works

1. **It defines the trust boundary in one sentence.** "Anything running on the user's device is under the user's control" is the model correction; every variant of the bug falls out of forgetting it.

2. **It orders the work: server first, UI second.** The failure mode is finishing the visible half and stopping. Sequencing the server check first means an interrupted task fails safe instead of open.

3. **It distinguishes page guards from endpoint guards.** AIs that do add server checks often protect the page route and leave the JSON API open; naming that gap closes the most common partial fix.

4. **It makes "done" testable.** Requiring the 403-from-curl demonstration converts a vague principle into a binary check the AI can self-apply before declaring success.

## Origin

An internal dashboard added "manager-only" salary editing. The assistant delivered a clean implementation: the edit form rendered only for managers, the route redirected everyone else, and the demo to stakeholders went perfectly. The PATCH endpoint checked for a logged-in session and nothing more. An employee who'd watched the network tab during a normal edit replayed the request against a colleague's record, and HR discovered the control had been cosmetic for four months. The server-side check, added afterward, was five lines of middleware.
