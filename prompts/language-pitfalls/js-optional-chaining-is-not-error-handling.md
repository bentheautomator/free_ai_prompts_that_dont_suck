---
title: JS Optional Chaining Is Not Error Handling
slug: js-optional-chaining-is-not-error-handling
category: language-pitfalls
tags: [universal, javascript]
works_with: all
severity: high
one_liner: "Stops reflexive ?. from converting real bugs into silent undefineds"
---

# JS Optional Chaining Is Not Error Handling

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `?.` being sprayed on every property access until broken data flows through the system as `undefined` instead of failing where the bug is.

**[Copy-paste ready version](../../install/js-optional-chaining-is-not-error-handling.md)** — just the instruction block, no explanation.

## The Problem

Optional chaining answers one question: "is it expected and fine for this to be missing?" AI assistants use it to answer a different question: "could this possibly throw?" The result is code like `order?.customer?.address?.city ?? ''` in a code path where an order *always* has a customer — so when the upstream join breaks and `customer` comes back undefined, nothing throws. The empty string flows into the shipping label, the label prints blank, and the first sign of the bug is a support ticket from a courier, three systems and two weeks away from the broken join.

This is the worst trade in error handling: a loud, located crash (`TypeError` with a stack trace pointing at the bug) exchanged for silent `undefined` propagation that surfaces as corrupt output with no trace at all. `?.` also short-circuits method calls — `callback?.()` — which turns "we forgot to wire the callback" into "the feature silently does nothing."

Assistants over-apply `?.` because it pattern-matches as defensive, modern, and crash-free, and because they cannot see your data contracts. When the model doesn't know whether `customer` can be null, `?.` is the completion that never *looks* wrong. Sprinkling it is how generated code converts type errors into business-logic errors.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### JS Optional Chaining Is Not Error Handling

Use `?.` ONLY where absence is an expected, valid state you are deliberately handling. NEVER use it to suppress a crash on data that is supposed to be there — that converts a located TypeError into silent `undefined` propagating through the system.

- Before writing `?.`, answer: per the data contract, can this legitimately be missing? If yes, `?.` plus an explicit fallback or branch. If no, access it plainly and let it throw, or validate at the boundary and fail with a real error.
- Wrong: `const city = order?.customer?.address?.city ?? ''` when orders always have customers — a broken join now ships blank labels. Right: `order.customer.address` (crash at the bug) or boundary validation that rejects the malformed order loudly.
- `??`/fallback values deserve the same scrutiny: a default is a decision about business behavior, not a crash-prevention tool.
- `callback?.()` silently skips required wiring. Only use it for genuinely optional hooks.
- Do not chain `?.` after the first one reflexively: in `a?.b.c`, if `a` exists then `b` is being asserted to exist — make that assertion match the contract instead of autocompleting `?.` onto every link.
- When unsure whether a field is optional, do not guess with `?.`. Check the type/schema/API docs, or validate explicitly and throw a descriptive error.
- TypeScript: fix the type or narrow it; using `?.` to silence a type error has the same downstream cost.

**Red flags that you're about to violate this:**

- "I'll add `?.` everywhere to be safe."
- "Better to render nothing than to crash."
- "I'm not sure if this field is optional, `?.` covers both cases."
- "The linter/types complained, `?.` makes it green."
- "This fixes the reported TypeError." (It hides it. The data is still wrong.)
- "Defensive coding is good practice."

---

## Why It Works

1. **It redefines `?.` from a safety feature to a contract statement.** The model's prior treats `?.` as cost-free insurance; framing each `?.` as a claim ("this is validly optional") forces a decision instead of a reflex.
2. **It names the failure-mode exchange.** Located crash now vs. untraceable corruption later is the actual trade; once stated, "better than crashing" stops being a winning rationalization.
3. **It blocks the bug-hiding fix.** "This fixes the TypeError" is the exact thought during a bug-fix request; the rule makes clear the crash was the symptom pointing at the bug, not the bug.
4. **It gives the unsure-case protocol.** The model's weakest moment is not knowing the contract; "check or validate loudly, don't guess with `?.`" replaces the guess with a procedure.

## Origin

A bug report said a dashboard crashed with `Cannot read properties of undefined (reading 'name')`. The fix that shipped was `user?.profile?.name ?? 'Unknown'`. The real bug was a session refresh that returned users without profiles; with the crash silenced, every affected account rendered as "Unknown" and — because the same `?? ''` pattern was copied into the audit-log writer — three weeks of audit entries recorded empty actor names before anyone realized the original crash had been the only honest component in the pipeline.
