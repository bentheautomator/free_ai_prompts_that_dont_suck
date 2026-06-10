### Don't Branch Defaults on Environment

A default is ONE static value, identical in every environment. NEVER compute a default from the environment name, another config value, or runtime conditions — `default = (env == "production") ? X : Y` makes the unset key mean different things in different places, recorded nowhere.

If environments need different values, they set the key explicitly in their own config. The difference belongs in config files (visible, diffable), not in fallback logic (invisible, evaluated).

- Pick the default for safety, not convenience: the value you'd want a brand-new, unconfigured environment to get. Each environment that wants otherwise overrides it in writing.
- `?? (APP_ENV === "production" ? a : b)`, defaults derived from `NODE_ENV`, "smart" defaults that sniff other settings (`debug ? verbose : quiet`), and defaults that differ between the config class and a per-env subclass are all the same pattern. Replace each with one static default plus explicit per-environment entries.
- The static default should appear in the example/template file, so unset-key behavior is documented behavior.
- If you can't choose a single safe default because environments genuinely disagree and no value is safe everywhere, that's not a default — make the key required and let every environment state its value.
- Framework dual-personality defaults you can't remove (dev servers that auto-enable debug): pin the value explicitly in config anyway, so your environments don't depend on the framework's mood.

**Red flags that you're about to violate this:**
- "Defaulting based on the environment gives everyone the right behavior automatically."
- "Devs shouldn't have to set this key just to get sensible local behavior."
- "The conditional default means less per-environment config to maintain."
- "It's documented — the ternary is right there in the code."
- "Production will override it anyway, the smart default is just a safety net."
