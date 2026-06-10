---
title: Always Check Object Ownership Before Access
slug: always-check-object-ownership
category: security
tags: [universal, security, auth]
works_with: all
severity: critical
one_liner: "AI fetching records by ID without checking the requester owns them"
---

# Always Check Object Ownership Before Access

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents insecure direct object references: authenticated users reading and editing other users' records.

**[Copy-paste ready version](../../install/always-check-object-ownership.md)** — just the instruction block, no explanation.

## The Problem

`GET /api/invoices/:id`. The AI writes the obvious handler: check the user is logged in, `Invoice.findById(req.params.id)`, return it. Authentication: present. Authorization: absent. Any logged-in user who increments the ID in the URL reads every invoice in the system, because nothing ever asked whether *this* invoice belongs to *this* user. This is IDOR — insecure direct object reference — and it sits at the top of real-world API vulnerability lists precisely because the broken version looks complete. There's even an auth check in the handler. It's just answering the wrong question.

AI assistants generate IDOR at scale because CRUD scaffolding is their bread and butter and ownership is context they don't have unless the schema or prompt forces it. The bug worsens in the variants: update and delete handlers (same missing check, destructive consequences), nested resources where the child is checked but the parent isn't (`/orgs/2/projects/9` where project 9 belongs to org 5), list endpoints that filter client-side, and "unguessable" UUID keys treated as a substitute for the check — UUIDs leak, in logs, referrers, and other API responses.

The fix is mechanical: every query for a user-owned resource includes the owner in the lookup.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Always Check Object Ownership Before Access

NEVER fetch, update, or delete a record by client-supplied ID alone. Every query for a user-scoped resource must include the requester's identity (or an explicit permission check) in the lookup itself.

Authentication says who they are. It says nothing about whose invoice that is. Those are different checks, and the second one is the one AIs skip.

- Scope queries at the database: `Invoice.findOne({ _id: id, userId: req.user.id })`, `WHERE id = $1 AND owner_id = $2`, `current_user.invoices.find(params[:id])`. A miss returns 404, identical to "doesn't exist," so existence isn't leaked.
- Apply it to every verb. Read-only IDOR leaks data; unchecked PUT/PATCH/DELETE lets users edit and destroy other people's records. Update/delete handlers need the same scoped lookup, not a trailing `if` after an unscoped fetch.
- Check the whole chain on nested routes: `/orgs/:orgId/projects/:projectId/files/:fileId` requires verifying the file belongs to the project, the project to the org, and the requester to the org. Checking only the leaf lets attackers graft valid IDs onto other tenants.
- Never accept the owner from the request: `userId` in the body or query is attacker input. Take identity from the verified session/token only.
- UUIDs, hashids, and "unguessable" identifiers are not authorization; they leak through logs, referrers, exports, and adjacent endpoints. Do the check regardless of key format.
- Shared-access models (collaborators, teams) replace the ownership equality with a membership/permission lookup, still enforced server-side per request, and centralized in one helper or policy layer rather than re-improvised per handler.
- For list endpoints, filter by owner in the query itself, never fetch-all-then-filter in application code or, worse, the client.

**Red flags that you're about to violate this:**
- "The route already requires login, so it's protected..."
- "IDs are UUIDs, no one can guess another user's..."
- "The frontend only ever links to your own records anyway..."
- "I'll fetch the record first and we can add ownership filtering later..."
- "This is the admin codebase, scoping would just get in the way..."
- "The parent resource was checked upstream, the child must be fine..."

---

## Why It Works

1. **It separates the two questions the AI conflates.** "Logged in" versus "owns this record" is the precise confusion behind every IDOR; stating it as two distinct checks prevents the first from satisfying the second.

2. **It puts the check inside the query.** A scoped `findOne` cannot be forgotten on the way to the response, can't race, and uniformly returns 404. Structural enforcement beats remembering an `if`.

3. **It pre-rebuts the UUID defense.** "Unguessable ID" is the rationalization that feels most like security; explaining the leak channels (logs, referrers, exports) is what actually dislodges it.

4. **It extends to nested routes and writes.** Partial fixes — read-only checks, leaf-only checks — are the common failure after a first IDOR lesson; enumerating them makes the rule cover what the next bug report would have.

## Origin

A customer portal exposed `GET /api/statements/:id` with sequential IDs, written by an assistant that dutifully required a session token. A customer typo'd a digit in a bookmarked URL and got someone else's financial statement, then reported it, to the company's credit, instead of scripting it. The audit that followed found the same unscoped pattern in eleven endpoints, all generated in the same scaffolding session. The fix was one `AND account_id = ?` per query.
