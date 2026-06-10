### JSON Big Numbers Lose Precision

NEVER represent 64-bit integers (ids, snowflakes, nanosecond timestamps, cursors) as JSON numbers when any consumer might parse them as doubles. Above 2^53 (about 9.0e15), doubles silently round: `9007199254740993` parses as `...992`, and the corrupted id round-trips without error.

- Serialize 64-bit ids as JSON strings: `{"id": "9007199254740993"}`. APIs that must stay compatible can send both (`id` numeric legacy, `id_str` canonical) — consumers must use the string.
- In JavaScript/TypeScript, type ids as `string`. Never `parseInt`/`Number()` an id "to clean it up" — ids are opaque tokens; they're compared, stored, and passed, never used in arithmetic.
- If you must parse JSON containing large numerics you don't control, use a parser with bigint/raw-number support (`JSON.parse` reviver with source access where available, or a lossless-JSON library); stock `JSON.parse` has already destroyed the value by the time you see it.
- Server side: declare ids as strings in the schema (OpenAPI `type: string`), even when the database column is BIGINT. Convert at the storage boundary, not in transit.
- Proxies, loggers, and tools that parse-then-restringify JSON corrupt large numbers in payloads they merely forward — treat any parse step in the pipeline as a consumer.
- Floats in JSON have the cousin problem (decimal fractions are approximations); money amounts follow the same rule: strings or integer minor units, not JSON decimals.
- Small bounded integers (counts, ports, enum-ish codes) remain plain JSON numbers. The rule is about 64-bit-range values and opaque identifiers.

**Red flags that you're about to violate this:**

- "The id is an integer, so the JSON type should be a number."
- "I'll parse the id to a number for the comparison."
- "Our ids are nowhere near 2^53." (Snowflake ids passed it years ago; yours are timestamp-prefixed too.)
- "The API docs show the id without quotes."
- "I'm just reformatting the JSON, not changing values." (Your formatter parses it first.)
- "TypeScript says number, so number is correct."
