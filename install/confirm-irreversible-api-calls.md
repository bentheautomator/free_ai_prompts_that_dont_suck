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
