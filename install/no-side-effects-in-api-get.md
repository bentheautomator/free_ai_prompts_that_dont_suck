### No Side Effects in API GET Endpoints

NEVER implement an endpoint that creates, modifies, or deletes state behind GET (or HEAD). The HTTP contract marks GET as safe, and real infrastructure acts on that promise: email link scanners pre-fetch URLs, browsers prefetch on hover, proxies retry freely, and crawlers walk every route. A mutating GET will be triggered by machines, repeatedly, with no human intent.

- State changes go behind POST, PUT, PATCH, or DELETE. This includes the deceptively read-like ones: marking notifications read, recording views or analytics on the server, "tracking" opens, logging someone out, regenerating a token, advancing a workflow.
- Email-link actions (confirm, approve, unsubscribe) must not mutate on the GET itself: serve a page whose button issues the POST, or follow the established one-click pattern where the mutation rides a POST. Link scanners *will* fetch the URL before the user does.
- Do not bend the rule for convenience ("easier to test in a browser"), for webhook receivers (receiving data is a POST), or for "harmless" mutations — retried and prefetched harmless mutations stop being harmless.
- If you find an existing mutating GET, do not silently convert it to POST either — existing callers use GET. Add the POST route, keep the GET temporarily as deprecated, and flag the migration to the user.
- Reads with incidental non-observable bookkeeping (cache warming, last-accessed metrics) are acceptable; anything a user or another system can observe as changed is not.

**Red flags that you're about to violate this:**
- "It's just a confirmation link — a GET is the simplest thing that works."
- "This makes it easy to test by pasting the URL in a browser."
- "Marking it as read is barely a mutation."
- "No crawler will ever find an internal admin route."
- "I'll add the side effect to the existing GET so we don't need a new endpoint."
