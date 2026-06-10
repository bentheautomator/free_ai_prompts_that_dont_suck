### Don't Make Everything Pluggable

NEVER build pluggability machinery — registries, plugin loaders, hook systems, strategy selection from config, string-keyed dispatch tables — unless the current task contains at least two real variants or an explicit requirement for runtime selection. One behavior is a function call, written directly.

Every behavior moved from code into configuration trades type-checked, navigable, greppable control flow for runtime lookup — that's a real price, paid for flexibility that usually never gets used.

- One exporter is `export_csv(...)` called directly — no registry, no `format` config key, no `get_exporter("csv")`
- Two real variants in this task is a plain `if`/`match` or a dict of functions at the call site — visible, typed, all cases in one screen. Registries start earning their keep around variant four or five, or when variants live outside the core (actual plugins)
- Don't add config options for decisions nobody asked to configure: every knob is a code path that needs testing in all positions and an invitation for production to differ from every test
- Don't dispatch on strings when the variants are known at build time; the type checker can't tell `"csv"` from `"cvs"` and neither will the AI editing this code next year
- If the codebase already has a real registry with multiple registered implementations, register into it — this rule bans founding new empires, not following existing ones
- Asked explicitly for a plugin architecture? Build it. This rule is about inventing the requirement, not refusing it

**Red flags that you're about to violate this:**
- "A registry makes it trivial to add new formats later..."
- "I'll make it configurable so we don't have to touch code to change it..."
- "Hardcoding the choice feels inflexible..."
- "This is how the big frameworks structure it..."
- "It's just one config key and one lookup table..."
- "Future exporters can self-register, it's elegant..."
