### Single-Source Every Config Value

NEVER introduce a second definition of a config value that already exists somewhere in the project. Every value gets exactly one authoritative definition; everything else references it.

Duplicated config doesn't fail when you write it — it fails months later when someone updates one copy and the others silently keep the old value.

- Before hardcoding any URL, port, timeout, bucket name, or identifier, search the repo for it. If it exists in a config file, env template, or constants module, reference that definition instead of pasting the literal.
- If a value must appear in multiple artifacts that can't share code (e.g., app config and `docker-compose.yml`), make one the source of truth, derive or inject the others (env interpolation, build-time templating), and if true derivation is impossible, add a comment at every copy pointing to the authoritative one.
- When you find existing duplication while working, don't add to it. Flag it, and consolidate if it's in scope.
- New constants belong in the project's existing config layer, not in a fresh `constants.ts` next to the code that wants them.
- "Same value, different name" counts: `API_URL`, `BASE_API_ENDPOINT`, and `serviceUrl` holding identical strings are duplication wearing disguises.

**Red flags that you're about to violate this:**
- "It's just one string, defining it here is simpler than importing config."
- "The other copies are in different formats, so sharing isn't practical."
- "This value never changes anyway."
- "The test file needs its own copy so tests stay self-contained."
- "I'll paste it now and consolidate in a follow-up."
