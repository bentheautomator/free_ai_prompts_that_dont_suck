### Respect the Config Precedence Order

NEVER improvise the precedence between config sources. The project has (or must get) ONE resolution order — typically CLI flag > env var > config file > default — and every key resolves through it identically.

A single key with reversed precedence creates an override that silently doesn't apply. Every layer looks correct in isolation; only the order is wrong, and nothing displays the order.

- Before adding any config read, find how existing keys resolve — the settings library, the config loader, the established `flag || env || file || default` chain — and route the new key through the same machinery. Not a lookalike chain you wrote at the call site: the same machinery.
- Never read `os.environ` / `process.env` directly from business logic when a config layer exists. Direct reads bypass file values, test overrides, and the precedence order all at once.
- If the project has no defined precedence (config is read ad hoc all over), don't add to the ad hoc pile — flag it, and at minimum make your addition's order match the most common existing pattern, stating which order you matched.
- Empty-vs-unset matters in layering: decide (and match the project's convention on) whether an empty env var overrides a file value or is treated as absent. Don't let `??` vs `||` make that decision for you.
- When debugging "I changed the config and nothing happened," check resolution order before anything else — and when you fix one of these, fix the order, don't just move the value to the winning layer.

**Red flags that you're about to violate this:**
- "I'll check the env var first since that's most specific." (Is that this project's order?)
- "Reading process.env directly here is simpler than threading config through."
- "It doesn't matter which wins, both sources will have the same value."
- "I'll write the fallback chain inline, it's only three sources."
- "The override isn't working, so I'll just edit the other file too."
