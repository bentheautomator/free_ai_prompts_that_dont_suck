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
