---
title: Don't Couple Feature Modules Sideways
slug: dont-couple-feature-modules-sideways
category: architecture
tags: [universal, architecture, coupling]
works_with: all
severity: high
one_liner: "Feature A importing feature B's services because the function was there"
---

# Don't Couple Feature Modules Sideways

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from making one feature module import another feature's code, knitting independent features into a clump that must be understood, tested, and shipped together.

**[Copy-paste ready version](../../install/dont-couple-feature-modules-sideways.md)** — just the instruction block, no explanation.

## The Problem

The codebase is sliced into feature modules — `checkout/`, `loyalty/`, `referrals/` — peers that each depend downward on `core/` and `shared/`. The AI, working in `referrals/`, needs to compute a credit amount, and grep finds the perfect function in `loyalty/calculations.py`. Import added, task done. No cycle was created; no layer was violated; the linter is silent. But `referrals` now depends on `loyalty`, which means loyalty's maintainers can't change their internals without checking referrals, loyalty's test failures block referral deploys in a monorepo pipeline, and "can we kill the loyalty program?" just became a cross-feature surgery question.

Sideways imports defeat the entire point of feature slicing, which is independence: independently understandable, independently testable, independently deletable. Each lateral edge converts two independent features into one distributed feature with two names. And the edges accumulate invisibly — no single import looks like an architecture decision, so the dependency graph among features goes from a clean star (everything depends on core, nothing on each other) to a hairball, one convenient import at a time.

AI assistants add these edges because flat search results don't show module rank. A useful function in a sibling feature looks identical to a useful function in `shared/` — importable is importable. The taxonomy that makes one import fine and the other corrosive lives in the directory structure the AI didn't consult.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Couple Feature Modules Sideways

NEVER import from a sibling feature module while working inside another feature. Features depend downward — on `core/`, `shared/`, the domain layer — never on each other. A useful function in a sibling is not importable just because it's reachable.

Every feature-to-feature import converts two independently testable, deletable modules into one entangled pair, and the entanglement compounds with each edge.

- Before importing, classify the source: shared/core (fine, that's what it's for), your own feature (fine), a sibling feature (stop)
- If a sibling has logic you need, it's evidence the logic is actually shared: move it DOWN into `shared/` or `core/` (updating the sibling's call sites), then import it from there
- If what you need is the sibling's *behavior* (its data, its decisions — "what's this user's loyalty tier?"), that's an integration, not an import: use the codebase's sanctioned mechanism for cross-feature interaction — a public API the feature deliberately exposes, the domain layer, or events — and if none exists, flag it rather than improvising one
- Don't launder the dependency: copying the sibling's non-trivial logic wholesale, or re-exporting it through shared without moving it, preserves the coupling and hides it
- Trivial code (a three-line formatter) can simply be duplicated; independence is worth more than deduplicating three lines

**Red flags that you're about to violate this:**
- "The exact function I need already exists in the loyalty module..."
- "It's not a cycle and it's not upward, so the import is clean..."
- "Moving it to shared means touching another team's files..."
- "These two features are related anyway..."
- "It's only one import between siblings, the modules are still separate..."

---

## Why It Works

1. **It adds the missing classification step.** The failure happens because all importable symbols look equal; one explicit question — "is this a sibling feature?" — restores the rank information that grep strips away.

2. **It reads the urge as evidence.** Wanting a sibling's function usually means the function was mis-filed as feature-private; "move it down" fixes the filing error instead of leaning on it.

3. **It separates code-sharing from integration.** "I need their helper" and "I need their decision" are different problems with different correct answers; conflating them is how feature APIs get bypassed.

4. **It permits small duplication on purpose.** The deduplication instinct is the strongest force pulling toward lateral imports; explicitly pricing three lines of copy below one coupling edge removes the moral cover.

## Origin

A product org decided to sunset its gift-cards feature, scoped as "delete the module, two days." The deletion broke 31 call sites across five sibling features that had, over two years, imported gift-card helpers for currency rounding, code generation, and balance formatting — none of which had anything inherently to do with gift cards. The two-day deletion became a five-week extraction, most of it spent doing the move-to-shared refactors that each original import had skipped. The team's retro slide read: "every sideways import is a loan against the day you want to delete something."
