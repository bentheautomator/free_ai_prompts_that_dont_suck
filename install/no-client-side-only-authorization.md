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
