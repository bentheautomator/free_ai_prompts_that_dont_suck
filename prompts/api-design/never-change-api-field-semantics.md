---
title: Never Change API Field Semantics
slug: never-change-api-field-semantics
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: critical
one_liner: "Stops changing a field's meaning or units while its name and type stay the same"
---

# Never Change API Field Semantics

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing what a field means — cents to dollars, net to gross, UTC to local — while the name and type stay identical and nothing visibly breaks.

**[Copy-paste ready version](../../install/never-change-api-field-semantics.md)** — just the instruction block, no explanation.

## The Problem

Every other contract break at least *changes the payload*. This one doesn't. The field is still called `amount`, still a number, still present in every response — but it used to be cents and now it's dollars. Or `total` used to be net of discounts and now includes them. Or `duration` switched from seconds to milliseconds, `temperature` from Celsius readings to Fahrenheit, `created_at`'s timezone from UTC to server-local. Schema validators pass. Type checkers pass. Strict deserializers pass. Every consumer is now computing wrong numbers with full confidence.

This is the only contract failure with *no mechanical detector on the consumer side*. A missing field throws; a re-cased field reads undefined; a semantic change just produces values that are wrong by a factor of 100, silently, in systems that charge cards, pay invoices, and dose decisions on the data. It's the contract break most likely to end in money moving incorrectly.

AI assistants introduce it while "fixing" what looks like awkward internal handling: integer-cents arithmetic replaced with a decimal dollars type, a unit normalization applied for cleanliness, a discount applied one layer earlier so a downstream field now includes it. The refactor is locally coherent. The units leak through the serializer, and the field's name promises nothing changed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It names the absence of a detector.** Other breaks fail loudly somewhere; pointing out that schema, types, and deserializers all pass on a semantics change tells the AI its usual compatibility checks are structurally blind here.
2. **It makes the unit part of the contract by definition**, so "same name, same type" stops registering as evidence of compatibility.
3. **It prescribes new-name-for-new-meaning**, converting the change into an additive one where consumer adoption is a conscious act rather than an ambush.
4. **It extends semantics to inclusion rules**, catching the basis changes (net/gross, with/without tax) that carry no unit and so evade even careful unit-thinking.

## Origin

A refactor replaced integer-cents arithmetic with a decimal money type throughout a billing service, and the serializer began emitting `"amount": 49.99` where it had emitted `"amount": 4999`. Same field, same endpoint, valid JSON. A partner's invoicing system divided by 100 as it always had and generated invoices for roughly half a percent of the real amounts; it billed customers $0.49 subscriptions for most of a billing cycle. The under-collected revenue was eventually re-invoiced — along with several hundred awkward emails explaining why.
