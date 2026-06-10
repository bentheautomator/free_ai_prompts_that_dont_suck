### Pin API Serializer Config

NEVER change global serializer or framework settings that affect how existing API responses are rendered: property naming strategies, null/empty-field inclusion, date/time formats, enum rendering, key ordering with semantic effect, or pretty/compact structure changes that alter content. One config line rewrites every endpoint's wire format at once — it is the largest possible breaking change hidden in the smallest possible diff.

- Treat these as frozen once an API has shipped: naming policy (`SNAKE_CASE`/`CamelCase` strategies), `omit_empty`/`exclude_none`/`NON_NULL` inclusion, global date formats, enum-as-name vs enum-as-value, number-as-string flags.
- When upgrading or swapping serialization libraries, the new library must be configured to reproduce the OLD wire format exactly — not its own defaults, and not the new version's "improved" defaults. Migration guides list behavior changes; check them against your payloads.
- Verify by golden-file diff: capture real serialized responses from several representative endpoints before the change and byte-compare (or key/structure-compare) after. "The tests pass" is meaningless when the tests serialize with the same config you just changed.
- Scope any genuinely-wanted new convention to new surface area only: a separate serializer instance for new endpoints or the next API version. Global config changes apply to history, and history has consumers.
- If the user asks for an API-wide format change, spell out that this re-renames or re-shapes every field of every response for every consumer, and propose the versioned or opt-in route.

**Red flags that you're about to violate this:**
- "The framework's new default naming strategy is what the config should have been all along."
- "One config line is much cleaner than annotating every DTO."
- "I'm swapping serializers, but they're functionally equivalent."
- "Dropping null fields shrinks payloads — pure win."
- "All the serialization tests still pass after the upgrade."
