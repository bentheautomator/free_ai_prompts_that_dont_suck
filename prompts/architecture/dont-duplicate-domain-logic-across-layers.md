---
title: Don't Duplicate Domain Logic Across Layers
slug: dont-duplicate-domain-logic-across-layers
category: architecture
tags: [universal, architecture, layering]
works_with: all
severity: high
one_liner: "The same business rule reimplemented in UI, API, and database layers"
---

# Don't Duplicate Domain Logic Across Layers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from reimplementing a business rule in a second layer instead of calling the existing implementation, creating copies that will drift.

**[Copy-paste ready version](../../install/dont-duplicate-domain-logic-across-layers.md)** — just the instruction block, no explanation.

## The Problem

"An order over $500 needs manager approval." That rule exists in the domain service. Then the frontend needs to show the approval banner, so the AI writes `total > 500` in the React component. The API wants to reject early, so the validator gets its own copy. Someone asks for a report, and the SQL gains `WHERE total > 500`. Four implementations of one rule, in four languages, none aware of the others.

They drift, because they must. The threshold becomes $400 for one customer tier; the domain service gets updated, plus whichever copies the person doing the change happens to know about. Now the UI shows "approval required" for orders the backend waves through — or worse, the reverse, and the rule customers can observe is whichever layer they hit first. Each copy also re-states the rule at its layer's fidelity: the SQL doesn't know about tiers, the frontend doesn't know about the currency conversion, so the copies weren't even equal on day one.

AI assistants are world-class at this failure because each layer's task arrives separately, and reimplementing a rule from its description is exactly what they're good at. The rule is small; writing it again is faster than finding it. Nothing in any single diff reveals that the rule now exists in four places.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Duplicate Domain Logic Across Layers

NEVER reimplement a business rule that already exists in another layer. One rule, one implementation, one owner — every other layer calls it, asks it, or receives its verdict as data.

Copies of a rule are correct only on the day they're written; every subsequent change to the rule is a chance for the copies to disagree, and the user sees whichever copy their request hits.

- Before writing any conditional that encodes business knowledge (thresholds, eligibility, state transitions, pricing), search for that rule by its constants and its vocabulary; if it exists anywhere, call it instead of rewriting it
- Frontend needing a rule's verdict gets it FROM the backend: a `requires_approval` field on the API response, computed by the one real implementation — not a reimplementation in the component
- Database queries that need a rule (reports, filters) should consume values the domain layer computed and stored (a flag, a status column), not re-derive the rule in SQL
- Client-side pre-validation for UX is legitimate, but it's a *courtesy copy* of the server's rule: keep it trivial, derive it from server-provided data where possible (limits in the API response), and never let it be the only enforcement
- If you genuinely must duplicate (offline clients, performance), leave a comment at both sites naming the other location — drift you can find beats drift you can't

**Red flags that you're about to violate this:**
- "It's a one-line check, importing the service is heavier than writing it..."
- "The frontend can't call the domain layer, so I'll just re-code the rule..."
- "The report query needs the logic in SQL anyway..."
- "I know what the rule is, I don't need to find the existing one..."
- "The two implementations are identical, so it's fine..."

---

## Why It Works

1. **It moves verdicts instead of rules.** "Send `requires_approval: true` across the boundary" is the structural insight: data crosses layers cheaply and can't drift, while logic crossing layers always forks.

2. **It makes the search mandatory before the conditional.** Rewriting a small rule is faster than finding it *once*; the rule reprices that tradeoff against every future change to the rule.

3. **It legitimizes the UX copy with guardrails.** Client-side pre-validation is the one honest duplication need; giving it explicit rules (trivial, server-derived, never authoritative) stops it from becoming the precedent for the other kind.

4. **It makes unavoidable duplication discoverable.** Cross-referencing comments don't prevent drift, but they convert "unknown unknown" into a greppable pair — the difference between a five-minute fix and a quarter of mystery bugs.

## Origin

A lending product's eligibility rule lived in the underwriting service, the signup form, the marketing site's prequalification widget, and a nightly SQL job. A regulatory change moved one threshold. Three of the four got updated — the widget kept prequalifying people the underwriting service would decline, and rejected applicants had screenshots showing they qualified. Support escalations ran for six weeks before anyone thought to ask how many places the rule existed; the answer required reading four codebases and surprised every team involved.
