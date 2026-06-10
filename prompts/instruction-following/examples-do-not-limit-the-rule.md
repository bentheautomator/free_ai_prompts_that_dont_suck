---
title: Examples Do Not Limit the Rule
slug: examples-do-not-limit-the-rule
category: instruction-following
tags: [universal, rules, compliance]
works_with: all
severity: medium
one_liner: "AI applies a rule only to the examples the rule happened to list"
---

# Examples Do Not Limit the Rule

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from treating a rule's illustrative examples as the rule's complete and exclusive scope.

**[Copy-paste ready version](../../install/examples-do-not-limit-the-rule.md)** — just the instruction block, no explanation.

## The Problem

Your rules file says: "Never log sensitive data (passwords, tokens, credit card numbers)." The AI dutifully avoids logging passwords, tokens, and credit card numbers — and logs email addresses, session IDs, and full request bodies without a second thought. The parenthetical was three examples of a category. The AI read it as the category's complete member list.

This is rule-following at the wrong level of abstraction. Examples in rules exist to anchor a general principle: "(e.g., passwords, tokens)" means *things like these*. But examples are concrete and the principle is abstract, so the examples win the pattern-match. The effect is a rule with invisible holes everywhere its author didn't enumerate — and authors never enumerate fully, because the entire point of stating a category is to not have to. The failure also runs in a second direction: rules demonstrated with one technology get scoped to that technology ("write integration tests for new endpoints — e.g., for the REST routes" silently excludes the GraphQL resolvers added later).

The user reasonably believes they prohibited a category. They actually got a blocklist of three items.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Examples Do Not Limit the Rule

A rule's examples illustrate its category — they NEVER define its boundaries. Apply the stated principle to every case it covers, including cases no example mentioned.

**The core problem:** Examples are concrete and principles are abstract, so you pattern-match on the examples and the rule silently shrinks to its example list. "Never log sensitive data (passwords, tokens)" becomes a two-item blocklist instead of a category.

**Do this:**

- When a rule gives examples ("e.g.," "such as," "like," a parenthetical list), extract the underlying category first, then test cases against the CATEGORY
- For each new case, ask: "Would the rule's author consider this the same kind of thing as the examples?" — if plausibly yes, the rule applies
- Treat technology-specific examples as illustrations: a rule demonstrated on REST endpoints covers GraphQL resolvers, RPC handlers, and whatever else fits the principle
- When you're genuinely unsure whether a case is in-category, apply the rule or ask — under-applying a category rule is the failure mode, not over-applying it

**Do not:**

- Treat anything absent from the example list as permitted
- Require an exact match with an example before the rule fires
- Use "the rule doesn't mention X" as a conclusion — examples not mentioning X is the normal condition for in-category items

**Red flags that you're about to violate this:**

- "The rule lists passwords and tokens, and this is neither"
- "That rule is about REST endpoints; this is GraphQL"
- "If they'd wanted X covered, they'd have included it in the list"
- "This case isn't an exact match for any example given"
- "The examples define what they actually cared about"

---

## Why It Works

1. **It mandates category extraction before matching.** The failure is matching cases against examples directly. Inserting an explicit step — name the category, then test against it — moves the comparison to the level where the rule actually lives.

2. **It installs the author test.** "Would the rule's author consider this the same kind of thing?" is a question models answer well — it converts boundary cases from lexical lookups (is it on the list?) into intent judgments (is it the kind of thing meant?).

3. **It inverts the absence inference.** "Not mentioned, therefore permitted" is the load-bearing fallacy. Pointing out that non-mention is the *normal* state of in-category items dissolves the inference instead of merely forbidding it.

4. **It sets the safe default for uncertainty.** Category boundaries are fuzzy; some cases are genuinely arguable. Defaulting arguable cases to "apply or ask" ensures fuzziness widens compliance rather than narrowing it.

## Origin

A rules file required confirmation before "destructive operations (e.g., DROP TABLE, rm -rf, force-push)." The assistant, cleaning up a test environment, truncated four tables without asking — TRUNCATE wasn't on the list. One of the tables was shared with a staging environment another developer was mid-demo on. The rule's author had named three examples of "destructive" and assumed the category was obvious. It was obvious. The list was just easier to match against.
