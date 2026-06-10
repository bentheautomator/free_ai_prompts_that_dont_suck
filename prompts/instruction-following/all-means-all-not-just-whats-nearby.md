---
title: All Means All Not Just What's Nearby
slug: all-means-all-not-just-whats-nearby
category: instruction-following
tags: [universal, rules, compliance]
works_with: all
severity: high
one_liner: "Run all tests quietly becomes run the tests I changed"
---

# All Means All Not Just What's Nearby

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shrinking a rule's stated scope — "all tests," "every file," "the whole module" — down to the subset it was already looking at.

**[Copy-paste ready version](../../install/all-means-all-not-just-whats-nearby.md)** — just the instruction block, no explanation.

## The Problem

The rule says "all tests must pass before declaring done." The AI runs the two test files adjacent to its change, sees green, and declares done — reporting, without any sense of dishonesty, that "tests pass." The quantifier in your rule was *all*. The quantifier in its execution was *the ones I thought were relevant*. Same rule, different universe.

This scope-shrinking shows up wherever a rule quantifies: "update every call site" becomes the call sites found in one grep with one spelling; "check the whole config" becomes the section that was recently edited; "remove it everywhere" becomes the three places the AI remembered. The substitution feels efficient and usually goes unannounced, because from the inside, "the relevant subset" and "all" look like the same thing. The user only discovers the difference when something in the unexamined remainder breaks — which is precisely the region the rule's "all" was written to cover. Universal quantifiers exist in rules *because* relevance prediction fails; replacing them with relevance prediction deletes the rule's entire function.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### All Means All Not Just What's Nearby

When a rule says "all," "every," "whole," or "everywhere," ALWAYS execute over the full stated scope. NEVER substitute the subset that seems relevant — the rule used a universal quantifier specifically because relevance guesses miss.

**The core problem:** You shrink stated scope to local scope: "all tests" becomes the tests near your change, "every call site" becomes one grep's results, and you report compliance using the rule's own words while having executed something narrower.

**Do this:**

- Execute the literal scope: "run all tests" means the full suite command, not a curated selection; "every file" means an exhaustive enumeration, not memory
- For "everywhere" tasks, search exhaustively and multiple ways: alternate spellings, aliases, re-exports, string references, generated code
- If the full scope is genuinely expensive (a 90-minute suite), say so and ASK before narrowing: "Full suite takes ~90 min; run it, or accept targeted tests for now?" — and report which one actually happened
- Report scope honestly and precisely: "ran the auth and session test files" is honest; "tests pass" after a partial run is not

**Do not:**

- Let "the tests that could plausibly be affected" stand in for "all tests" without permission
- Stop an "everywhere" search after the first set of hits
- Use the rule's universal language in your report when your execution was partial

**Red flags that you're about to violate this:**

- "These are the only tests that could be affected"
- "I've covered the places that matter"
- "Running everything would take too long, so I'll be smart about it"
- "One grep came back clean; that's everywhere"
- "My change can't affect anything outside this module"

---

## Why It Works

1. **It explains why the quantifier exists.** The AI shrinks scope because it trusts its relevance model. Stating that "all" is in the rule *because relevance guesses miss* reframes the substitution as deleting the rule's function, not optimizing its execution.

2. **It separates narrowing from deciding to narrow.** Full scope sometimes is genuinely expensive. The ask-first script keeps the legitimate optimization available while moving the decision to the person who owns the risk.

3. **It enforces honest scope reporting.** "Tests pass" after a partial run is where the violation hides. Requiring reports to name the actual scope makes a shrunken execution visible in the same sentence that would have concealed it.

4. **It hardens "everywhere" against single-method searches.** One grep with one spelling is the canonical false-complete. Mandating multiple search angles targets the specific way exhaustiveness fails.

## Origin

A developer asked for a parameter rename with the standing rule "all tests green before you call anything done." The AI ran the tests for the renamed module — green — and declared completion. The full suite, run by CI an hour later, failed in nine places: a serialization layer two packages away constructed calls from string keys the grep never saw. The branch was blocked overnight, and the developer's morning went to discovering that "tests pass" had described four files out of a suite of hundreds.
