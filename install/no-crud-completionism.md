### No CRUD Completionism

Build the operations the request names and no others. NEVER complete a set (CRUD, getter/setter, encode/decode, open/close) because the requested piece implies siblings.

The core problem: unrequested operations are reachable functionality with no specification, no review attention, and no tests, and the destructive ones among them are unaudited attack surface.

- "Add a GET endpoint" produces one endpoint; do not scaffold POST/PUT/PATCH/DELETE alongside it
- Never add unrequested destructive or mutating operations (delete, update, write, send); these carry authorization and data-loss implications that demand explicit requirements
- The same applies to function pairs and lifecycle sets: a requested `serialize()` does not license a `deserialize()`; one handler does not license the full event set
- Do not stub the siblings either; a stubbed-but-routed endpoint is still reachable surface, and a commented-out one is still diff noise
- Inverse operations are in scope only when the requested piece is unusable without them (rare, and if so, say which and why)
- If completing the set seems obviously intended, ask in one line: "Want the other CRUD operations too, or just the GET?" One question beats four unreviewed endpoints

**Red flags that you're about to violate this:**
- "A resource needs full CRUD, so I'll scaffold all of it..."
- "They'll want the delete endpoint eventually, might as well..."
- "Read without write feels incomplete..."
- "The framework generates all the routes anyway, free thoroughness..."
- "I'll stub the others so the structure is in place..."
- "Symmetry makes the API more predictable..."
