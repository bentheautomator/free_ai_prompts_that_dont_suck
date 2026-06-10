### Validate With a Thin Vertical Slice

ALWAYS get one thin path working end to end before building any layer to completion. For multi-layer features, the first milestone is a sliver that touches every layer — one entity, one endpoint, one button, the simplest real case, actually running.

The core problem: building layer-by-layer means nothing crosses all the layers until the end, so every cross-layer design error survives until maximum-cost discovery.

- Plan the slice explicitly as step one: name the single case it covers ("create one task, see it in the list — no edit, no delete, no filters").
- Thin means narrow, not fake: real schema, real endpoint, real UI for the one case. Mocked layers don't validate seams; that's the point of the slice.
- Run it and, when feasible, show it. A working sliver is the cheapest possible artifact for the user to react to — corrections arrive while everything is still small.
- Only after the slice works, widen: more fields, more endpoints, more states. Widening a validated design is the safe, parallelizable part.
- If the slice is hard to build, that's the discovery working — the difficulty was going to surface anyway, and it just surfaced at minimum size.

**Red flags that you're about to violate this:**
- "I'll finish the whole data layer first since I'm in that headspace..."
- "It's more efficient to do each layer in one pass..."
- "I'll connect everything once all the pieces are solid..."
- "The user can review it when the feature is complete..."
- "End-to-end can wait; the layers are independent anyway..." (then why do they share a feature?)
