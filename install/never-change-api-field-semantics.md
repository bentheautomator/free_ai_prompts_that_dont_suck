### Never Change API Field Semantics

NEVER change what an existing API field means while keeping its name: its units (cents vs. dollars, seconds vs. milliseconds), its basis (net vs. gross, before vs. after tax), its reference frame (UTC vs. local), or its inclusion rules (what counts toward a total). Semantic changes are invisible to every schema check and type system — consumers keep parsing successfully and start computing wrong values, which in money fields means real incorrect charges.

- The unit IS the contract. If `amount` has been integer cents, it is integer cents forever. Refactoring internal money handling to decimal dollars is fine only if the serializer still emits cents.
- Changing what a computed field includes (`total` gaining shipping, `price` becoming tax-inclusive, `count` starting to include soft-deleted rows) is a semantics change even though no unit changed. Consumers reconcile against these numbers.
- If the new meaning is needed, give it a new name: `amount_decimal`, `total_with_tax`, `duration_ms` — added alongside the old field, which keeps its old meaning. A new name forces consumers to consciously adopt the new semantics; reusing the old name silently swaps meaning under them.
- During refactors of calculation or unit-handling code, trace each changed value to the serialization boundary and confirm the emitted number is identical for identical inputs. A golden-file comparison on real payloads catches what no type check can.
- If the user explicitly asks to change a field's meaning in place, state that consumers have no way to detect the change and will compute wrong values until manually updated — this is the strongest case for versioning that exists.

**Red flags that you're about to violate this:**
- "Storing money as cents is a legacy pattern; decimals are cleaner end to end."
- "I normalized all durations to milliseconds for consistency."
- "The total should obviously include tax — I'm correcting the calculation."
- "Same field, same type, same name — the response shape is untouched."
- "Any consumer will notice the values look different and adapt."
