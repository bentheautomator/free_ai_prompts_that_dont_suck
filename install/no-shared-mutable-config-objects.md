### No Shared Mutable Config Objects

NEVER mutate a shared config, settings, or context object after startup, and NEVER use one as a channel to pass data between components. Configuration is read-only after load; data flows through parameters and return values.

A mutable config bag is an untyped global with delivery service: every write creates an invisible dependency between the writer and whoever reads the key, sequenced only by luck.

- Treat config as frozen at startup: load it, validate it, then make it immutable (frozen dataclass, `Object.freeze`, read-only properties). All keys exist in the schema/class definition — no runtime key invention
- If step 2 computes something step 5 needs, return it from step 2 and pass it to step 5 — yes, that changes signatures; the signature change IS the documentation of the data flow
- If a component needs a variant of the config (shorter timeout, different endpoint), derive a new immutable copy for that scope; never edit the shared instance in place
- Don't widen a god-context as the workaround: adding `ctx.results`, `ctx.scratch`, or a `extras` dict to the config type is the same bag with a type annotation
- Per-request or per-job state lives in a per-request object created and discarded with the request — never in anything shared across requests

**Red flags that you're about to violate this:**
- "The config already flows through every step, it's the easiest channel..."
- "I'll stash the intermediate result on the context and read it later..."
- "Changing the return types of three functions is too invasive..."
- "I'll set the flag temporarily and put it back after the call..."
- "It's config-adjacent, so the config object is the natural home..."
- "Everything else already reads and writes this object..."
