### Keep API Response Envelope Stable

NEVER add, remove, or restructure the envelope of an existing endpoint's response — no wrapping bare payloads in `{"data": ...}`, no unwrapping existing envelopes, no renaming envelope keys, no converting a top-level array to an object or vice versa. Moving every field one level deep (or shallower) breaks all consumers at once, exactly like renaming every field simultaneously.

- A mixed API — some endpoints enveloped, some bare — is each endpoint's individual contract, not a defect to unify. Consistency is for endpoints that don't exist yet.
- Top-level array ↔ top-level object is the sharpest version: `response.map(...)` versus `response.data.map(...)` cannot both work, so there is no client that survives the change by accident.
- Beware one-line blast radius: global response interceptors, serializer base classes, and "standardize API responses" middleware change every endpoint's envelope in a single edit. Any such change must explicitly exempt all shipped endpoints.
- Adding *siblings inside* an existing envelope (a new `meta` key next to `data`) is additive and fine. Adding the envelope itself is not. Note: if the response is currently a top-level array, there is nowhere compatible to put metadata — that's a new-version problem, not a wrapping problem.
- If the user wants a uniform envelope, apply it to new endpoints and new API versions, or offer it via opt-in (header or query param) on existing ones, with the default shape unchanged.

**Red flags that you're about to violate this:**
- "Half the endpoints wrap responses and half don't — I'll standardize them."
- "Wrapping in a data key now gives us room for metadata later."
- "The envelope is pure boilerplate; unwrapping simplifies every client."
- "One interceptor fixes the response format everywhere at once."
- "No field names changed, so consumers are unaffected."
