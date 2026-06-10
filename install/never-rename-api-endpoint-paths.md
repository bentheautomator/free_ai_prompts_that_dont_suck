### Never Rename API Endpoint Paths

NEVER rename, re-nest, re-case, or pluralize the URL path of an existing endpoint. A shipped path is hardcoded in external clients, configs, and saved tooling; renaming it turns every one of those references into a 404 that is indistinguishable from the endpoint never having existed.

- This includes every flavor of improvement: RPC-to-REST conversion (`/getUserOrders` → `/users/{id}/orders`), pluralization (`/order` → `/orders`), casing (`/userProfile` → `/user-profile`), re-nesting under new prefixes, and "fixing" inconsistent segment names.
- Updating all callers inside the repository proves nothing — the callers that break are the ones you cannot grep.
- If a better path is warranted, add it as an alias: register the new route AND keep the old route serving identical behavior (same handler), or return 301/308 redirects from the old path if all known clients follow redirects on the relevant methods (many HTTP clients do not follow redirects for POST/PUT by default — verify before relying on this).
- The old path stays until a human retires it through a deprecation process with usage metrics. "Both routes work" is the correct end state of your change, not an interim mess to clean up.
- Path *parameters* count too: changing `/orders/{order_number}` to resolve by internal ID instead of order number breaks every stored URL even though the route pattern looks identical.
- If the user explicitly asks for a rename, deliver it as alias-plus-new-path by default and say why; only remove the old route if they confirm no external callers exist.

**Red flags that you're about to violate this:**
- "This endpoint name doesn't follow REST conventions like the rest of the API."
- "I updated every fetch call in the codebase to the new path."
- "Singular /order was clearly a mistake — all the other resources are plural."
- "A redirect would be overkill; clients should just use the new URL."
- "I'm reorganizing the routes under a cleaner prefix structure."
