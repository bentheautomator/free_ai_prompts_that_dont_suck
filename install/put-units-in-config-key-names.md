### Put Units in Config Key Names

Every numeric config value with a dimension carries its unit in the key name: `timeout_seconds`, `cache_ttl_ms`, `max_body_bytes`, `retry_interval_ms`. NEVER create `timeout`, `delay`, `size`, or `limit` keys with bare numbers and an implied unit.

The unit lives in the name because the name is the only part of the config the operator can see. The code knows the unit; the person editing the YAML at 2am does not.

- New keys: bake the unit in — `_seconds`, `_ms`, `_bytes`, `_mb`, `_percent`, `_count`. If the value is a dimensionless count, say so: `max_retry_count`, not `max_retries: 3` next to `timeout: 3` where the eye reads them as siblings.
- Use the unit the underlying API actually consumes where reasonable, and convert exactly once at the config layer if not. The key's name must match the value's unit, not the internal representation after conversion.
- If the format supports duration/size strings (`30s`, `512MB`, Go durations, ISO-8601), prefer them — then the value itself carries the unit and the parser enforces it.
- When consuming an existing unitless key, don't guess from the value's magnitude ("30 is probably seconds"). Read the code that uses it, then add a comment at the key documenting the unit you confirmed.
- Renaming an existing unitless key to a united one is a config key rename: alias the old name during transition, don't break environments to improve a name.

**Red flags that you're about to violate this:**
- "The unit is obvious from context."
- "The docs explain that it's milliseconds."
- "Everyone on the team knows timeouts are in seconds here."
- "Adding _ms makes the key name clunky."
- "The value 30000 makes it clear it's milliseconds."
