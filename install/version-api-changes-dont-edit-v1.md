### Version API Changes, Don't Edit v1

When a requested change to an API endpoint is breaking — different response shape, different semantics, removed or changed behavior — NEVER implement it by editing the existing version in place. A version number in the path (`/v1/`) is a stability promise; changing behavior under it betrays exactly the consumers who pinned it.

- Breaking changes go in a new version: `/v2/endpoint` alongside `/v1/endpoint`, or the project's equivalent (header versioning, date-based versions). The old version keeps its exact current behavior, served by code that still exists.
- Check before assuming: if the codebase already has a versioning scheme, use it. If it has none, surface the question to the user — "this change is breaking; should I add it as a new versioned endpoint or change it in place?" — rather than silently choosing in-place.
- Watch shared internals: modifying a service, formatter, or serializer that multiple versions call changes ALL versions. Implementing v2 must not reach through shared code into v1's behavior — fork or parameterize the shared path so v1's output is bit-for-bit unchanged.
- "Copy, then modify the copy" is correct engineering at a version boundary, even though it feels like duplication. The duplication is the feature: it's what lets v1 stand still.
- Version inflation is also real: do not spin up a new version for changes that are purely additive (new optional fields, new endpoints). Versions are for breaks.

**Red flags that you're about to violate this:**
- "Creating a whole new version for one endpoint change is overkill."
- "The user asked for the new behavior — they didn't mention keeping the old one."
- "I'll just update the shared formatter; both versions get the improvement."
- "v1 is old anyway; surely everyone is meant to be on the new behavior."
- "Duplicating this handler violates DRY."
