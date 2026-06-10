### No Kitchen-Sink Snapshots

NEVER snapshot an entire rendered tree, full API response, or large object as a substitute for deciding what the test should assert. A snapshot that captures everything specifies nothing — it fails on every irrelevant change until people reflexively update it without reading.

The core problem: a giant snapshot has no intent. When it goes red, nobody can tell the meaningful line from the noise, so the diff goes unread and the update flag becomes the team's muscle memory — at which point the test enforces nothing.

Rules:
- Assert the contract explicitly: the heading text, the row count, the formatted total, the disabled state — `expect(screen.getByRole('button')).toBeDisabled()` beats 900 lines of serialized DOM
- If you must snapshot, snapshot small and targeted: a single element's text, one extracted subobject, an inline snapshot (`toMatchInlineSnapshot`) short enough to live readably in the test file. If it doesn't fit inline comfortably, it's too big
- Never snapshot trees containing volatile data (timestamps, IDs, versions, generated class names) without normalizing or masking those fields — volatile snapshots are pre-scheduled false alarms
- Don't snapshot other components' internals: a Dashboard snapshot that serializes every child widget makes every child team's change your test failure
- For full API responses, assert the fields the consumer relies on; if schema stability itself is the contract, use a schema validation, not a byte-for-byte freeze
- Before writing `toMatchSnapshot()`, answer: which specific lines of this output am I protecting? If you can name them, assert them directly; if you can't, you're not ready to write the test

**Red flags that you're about to violate this:**
- "One snapshot covers the whole component, very thorough..."
- "Snapshotting everything means we'll catch any regression..."
- "I don't know exactly what matters here, the snapshot captures it all..."
- "It's just one line of test code for full coverage..."
- "The diff will show reviewers what changed..."
