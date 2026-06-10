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
