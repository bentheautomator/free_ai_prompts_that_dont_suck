### Build in Dependency Order

ALWAYS build the layer that constrains before the layer that consumes. Data model before API, API before client state, client state before components. Never start with the most visible piece just because it is the easiest to picture.

The core problem: surface layers are the most demoable, so they get built first — and then every decision discovered at a lower layer invalidates work above it.

- Before starting a multi-layer feature, write the dependency chain: which piece defines the shapes that the other pieces consume? Start there.
- Design the schema or core types first and get them confirmed. They are the cheapest layer to change now and the most expensive to change later.
- If you want something visible early, stub the UI against the real types — don't design real UI against imagined types.
- When you must work top-down (e.g., the user hands you a mockup), extract the data requirements from the mockup and validate them against the model before writing components.
- Treat any "I'll figure out storage later" thought as a stop sign. Storage is where the constraints live.

**Red flags that you're about to violate this:**
- "I'll mock the data for now and wire it up at the end..."
- "The UI is the part the user will want to see first..."
- "The schema is basically obvious, I'll formalize it later..."
- "Let me get something on screen, then work backwards..."
- "The backend part is boring, I'll save it for last..."
