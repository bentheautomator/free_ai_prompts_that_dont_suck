---
title: JS No Float Money Math
slug: js-no-float-money-math
category: language-pitfalls
tags: [universal, javascript]
works_with: all
severity: critical
one_liner: "Stops JS floating-point arithmetic from silently corrupting money values"
---

# JS No Float Money Math

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents prices and balances being computed with IEEE 754 floats, where `0.1 + 0.2 !== 0.3` and pennies leak.

**[Copy-paste ready version](../../install/js-no-float-money-math.md)** — just the instruction block, no explanation.

## The Problem

`0.1 + 0.2 === 0.30000000000000004`. Every JavaScript number is an IEEE 754 double, and most decimal fractions have no exact binary representation. Code like `const total = price * quantity * (1 - discount)` looks like arithmetic but is actually approximation. A cart of three $19.99 items computes to `59.967000000000006`, then `toFixed(2)` rounds it, then another code path recomputes from the raw floats and gets a different rounding, and now the invoice, the payment charge, and the ledger disagree by one cent.

One cent sounds harmless until it isn't: reconciliation jobs flag mismatches, payment providers reject amounts that don't match the authorization, refund totals drift from charge totals, and `total === expectedTotal` checks fail intermittently depending on the order of operations. The bugs are input-dependent, so unit tests with round numbers pass forever.

Assistants generate float money math because nearly every tutorial, example, and training snippet stores prices as `19.99`. The wrong version is the statistically dominant version. Without an explicit rule, the model will write `amount * 0.07` for tax in a billing system without blinking.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### JS No Float Money Math

NEVER do arithmetic on money as floating-point decimals in JavaScript. Every JS number is an IEEE 754 double; `0.1 + 0.2 !== 0.3`, and repeated operations accumulate drift that corrupts totals by real cents.

- Store and compute money in integer minor units (cents, satoshi, etc.): `1999` for $19.99. Integers are exact up to `Number.MAX_SAFE_INTEGER` (9 quadrillion cents).
- Wrong: `total += item.price * item.qty` with `price = 19.99`. Right: `totalCents += item.priceCents * item.qty`.
- Convert to decimal display only at the last moment: `(cents / 100).toFixed(2)` for display, or better, `Intl.NumberFormat` with a currency option.
- Percentages and division create fractions of a cent. Round explicitly at a defined point with a defined mode (`Math.round`, banker's rounding if the domain requires it) — never let `toFixed` be the accidental rounding policy, and never round twice.
- For high-precision or multi-currency math, use a decimal library or `BigInt` minor units; do not hand-roll with floats "carefully."
- Never compare computed money values with `===` on floats. If floats are already in the codebase and can't be removed, compare against an epsilon and say so in a comment.
- Parsing user input: parse `"19.99"` into integer cents directly (split on the separator); `parseFloat` then `* 100` yields `1998.9999999999998` for some inputs.

**Red flags that you're about to violate this:**

- "It's just two decimal places, doubles handle that fine."
- "I'll `toFixed(2)` at the end, that cleans up any drift."
- "The existing schema stores price as a float, so I'll keep computing in floats."
- "Multiplying by 100 converts it to cents safely."
- "This is an internal estimate, the exact cents don't matter." (It will be reused for billing.)
- "Adding a decimal library is overkill for one calculation."

---

## Why It Works

1. **It replaces a vague fear with a concrete representation rule.** "Be careful with floats" does nothing; "integer minor units, convert at display time" is a default the model can apply mechanically.
2. **It closes the `* 100` loophole.** The most common "fix" the model reaches for — multiply by 100 to get cents — is itself float math and is named as wrong with the exact failing output.
3. **It makes rounding a policy, not an accident.** Most penny-drift bugs are really two code paths rounding at different points; demanding one explicit rounding point removes the ambiguity.
4. **It pre-empts the dominant rationalization.** "Two decimal places is fine" is precisely the thought in the training data where this bug lives; naming it interrupts the completion.

## Origin

A subscription service computed proration as `monthlyPrice * (daysRemaining / daysInMonth)` in floats, charged the result, and separately recorded `monthlyPrice - prorated` as the credit. For certain month lengths the two float computations rounded differently and the charge plus the credit exceeded the monthly price by one cent. The payment provider's reconciliation flagged thousands of one-cent mismatches at month end, and finance spent a week proving the company hadn't been skimming its own customers.
