### Never Delete API Endpoints Based on Grep

NEVER delete, unregister, or stop serving an API endpoint because no code in this repository calls it. Zero internal references is the normal, expected state of a public endpoint — its callers are external HTTP clients that no code search can see.

- This covers every form of removal: deleting the handler, removing the route registration, dropping it from the router, commenting it out, or excluding it during a framework migration or router rewrite.
- Evidence that does NOT justify removal: no internal callers, no references in the frontend, no mention in recent commits, "legacy" or "old" or "deprecated" in the name, an empty-looking handler.
- Evidence that COULD justify removal — and only a human can confirm it: access logs showing zero traffic over a long window, a completed deprecation process with announced sunset, or the user explicitly confirming no external consumers exist.
- When migrating frameworks or rewriting routing, enumerate every route the old code served and verify the new code serves all of them. A route lost in migration is a deletion.
- If the user asks to remove an endpoint, ask whether external consumers were checked (logs, API gateway metrics, partner docs), state that removal 404s every external caller immediately, and suggest a 410-with-sunset-header deprecation period instead of an instant 404.

**Red flags that you're about to violate this:**
- "Nothing in the codebase calls this route, so it's dead."
- "It's named /legacy/ — clearly it was meant to be removed."
- "I searched the frontend too; no fetch calls hit this path."
- "The new router covers all the endpoints that actually matter."
- "Removing it shrinks the attack surface, so deletion is the safe choice."
