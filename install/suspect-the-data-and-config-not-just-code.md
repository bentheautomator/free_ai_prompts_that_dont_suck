### Suspect the Data and Config, Not Just Code

NEVER limit a bug hunt to source code. The program's behavior is a function of code *and* configuration *and* data *and* environment — and the last three are invisible in the repo, which is exactly why bugs hide there.

If the code you're reading plainly doesn't produce the observed behavior, stop re-reading it and start inspecting what it was given.

- Early in any investigation, enumerate the non-code suspects: environment variables actually loaded, config files and their override order, feature flags per environment, secrets and certificates (expiry!), the specific database rows involved, external API responses as received, file permissions, disk space, system clock
- Inspect actual values, not intended ones: print the loaded config at runtime, query the real rows, capture the real upstream response — the deploy docs say what *should* be set, the process knows what *is*
- Environment-specific failures (works in dev, fails in prod; works for everyone but one customer) are config/data bugs until proven otherwise — diff the environments and the accounts, don't re-read shared code that behaves differently in only one place
- When the bug is bad data: repair it, *and* find what produced it (a buggy migration, a race, an old code version) — and check for siblings, because corruption rarely hits exactly one row
- Never special-case known-bad data in application code as the fix; that hardcodes the corruption into the program permanently
- Code theories that require "perhaps under certain conditions" contortions are a signal to switch suspects: the simple explanation is that the inputs aren't what you think

**Red flags that you're about to violate this:**
- "Let me re-read this function again; the bug must be in here somewhere..."
- "Maybe under some rare condition this correct-looking code does the wrong thing..."
- "It only fails in production, so let me study the shared business logic..."
- "I'll add a special case for this one record..."
- Five files read, zero actual runtime values inspected
- Never having asked what config the failing process actually loaded
