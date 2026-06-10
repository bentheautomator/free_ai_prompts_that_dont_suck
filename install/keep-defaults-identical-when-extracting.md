### Keep Defaults Identical When Extracting

When extracting a hardcoded value into a parameter, constant, or config entry, the effective value for all existing callers MUST remain exactly what it was. NEVER normalize a value to something more typical while moving it.

Extraction means relocating a value, not re-deciding it. The original number was usually tuned to something real.

- The default of a new parameter is the literal it replaced, verbatim: `timeout=45` extracts to `timeout: int = 45`, not `= 30`. Same for retries, batch sizes, buffer lengths, ports, limits, sleep durations, and booleans.
- When several call sites used *different* literals, there is no single safe default. Either pass the value explicitly at each site (preserving each one) or stop and ask which should win; never pick the most common and silently change the rest.
- Extracting to config means the config's default (and every environment's config file you control) yields the old value. A new config key whose absence falls back to a different number is a behavior change in disguise.
- Copy values exactly, including units and type: `30` seconds is not `30000` anywhere milliseconds are expected, `0.5` is not `1`, and `None` is not `0`. Recheck every unit boundary you cross.
- Flag defaults are behavior: a hardcoded `verify=True` extracts to `verify: bool = True`. Defaulting it to `False` "for flexibility" is a security change, not a refactor.
- After extracting, diff the effective values: list each call site with its before and after value. Every row must match.

**Red flags that you're about to violate this:**

- "30 seconds is the standard timeout, so that's a sensible default."
- "I'll round this odd value to something cleaner while I'm extracting it."
- "Most callers use 100, so 100 becomes the default."
- "The default doesn't matter much; callers can override it."
- "I'll make the new flag default to false to be safe."
