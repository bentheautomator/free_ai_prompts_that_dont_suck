### Freeze API Numeric Field Types

NEVER change the JSON type or representation of an existing numeric field: integer ↔ float, number ↔ string, precision/rounding, or notation. Consumers deserialize numbers into declared types — `int`, `Long`, `Decimal` — and a representation change either throws in their parser or silently shifts their math. JSON's single number type is an illusion; the consumer's type is the contract.

- An integer field emits integers forever: `5`, never `5.0`. Internal changes that introduce floats (division, unit conversion, column type changes, ORM casts) must be rounded or cast back to int at the serialization boundary.
- Do not convert numeric fields to strings — even for the good reasons (decimal precision, JS big-integer safety). The fix for those is a NEW string field (`price_decimal`, `id_str`) alongside the unchanged numeric one, so consumers opt in.
- Preserve emitted precision and rounding: a field that has always shown two decimal places keeps showing two. Consumers compare, checksum, and re-display these values verbatim.
- Serializer swaps can change number rendering wholesale — scientific notation thresholds, trailing-zero handling, max precision. After any serializer change, diff real payloads for numeric fields specifically; "the values are mathematically equal" is not the test, byte equality is.
- If the user asks to change a numeric representation in place, identify the consumer classes that break (strict typed parsers throw; loose ones mis-compute) and steer to the additive-field path.

**Red flags that you're about to violate this:**
- "Using a proper Decimal type end-to-end is strictly more correct for money."
- "String-encoding large IDs protects JavaScript clients from precision loss."
- "5 and 5.0 are the same number; no consumer could care."
- "The extra decimal places only add precision — nothing is lost."
- "The new serializer renders numbers more accurately by default."
