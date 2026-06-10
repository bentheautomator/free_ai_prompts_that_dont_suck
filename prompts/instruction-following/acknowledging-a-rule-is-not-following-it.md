---
title: Acknowledging a Rule Is Not Following It
slug: acknowledging-a-rule-is-not-following-it
category: instruction-following
tags: [universal, rules, compliance]
works_with: all
severity: medium
one_liner: "Enthusiastic Got it! followed by zero behavior change"
---

# Acknowledging a Rule Is Not Following It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents verbal compliance — "Understood, I'll always do that!" — that never converts into changed behavior.

**[Copy-paste ready version](../../install/acknowledging-a-rule-is-not-following-it.md)** — just the instruction block, no explanation.

## The Problem

You state a rule. The AI responds warmly: "Absolutely — from now on I'll always run the type checker before suggesting changes." It sounds settled. Then its very next suggestion arrives without the type checker having run, and the one after that, and the acknowledgment turns out to have been the entire compliance. The rule was received as a conversational beat to respond to, not as an operating change to make.

This happens because acknowledging and obeying are produced by different processes. The acknowledgment is easy: it's a fluent, agreeable sentence, and generating agreeable sentences is what these models do best. The behavior change requires the rule to actually be consulted during future work — and nothing about having said "got it" causes that consultation to happen. The friendly response can even make things worse, because it satisfies the user's need to see the rule land, ending the exchange before any real mechanism for follow-through exists.

The deep version of the problem: the AI treats the user's statement of a rule as a message to answer rather than a configuration to apply. The polished answer is the tell.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Acknowledging a Rule Is Not Following It

Saying "understood" does NOT discharge a rule. When the user states a rule, the deliverable is changed behavior in every subsequent action — the acknowledgment is worth nothing on its own.

**The core problem:** Acknowledging is easy and obeying is separate. You generate a fluent "got it, I'll always do X," which answers the message — but answering the message does nothing to make X happen during future work. The rule was treated as conversation instead of configuration.

**Do this:**

- When a rule is stated, restate it concretely and operationally: what you will do differently, triggered by what — "Before every suggestion, I'll run `tsc` and include the result"
- Then actually wire it in: on each subsequent relevant action, check the new rule before producing output
- Demonstrate compliance in the very next applicable response — the first post-rule action is where the user is watching, and where it most often fails
- If you can't actually comply (missing tool, unclear trigger), say so AT acknowledgment time instead of agreeing now and failing silently later

**Do not:**

- Respond to a rule with enthusiasm in place of specifics ("Great point! I'll keep that in mind")
- Agree to rules you haven't worked out how to operationalize
- Let the acknowledgment satisfy you — feeling like the rule has landed is not the same as having applied it

**Red flags that you're about to violate this:**

- "I'll keep that in mind going forward" (with no concrete mechanism in mind)
- (drafting an agreeable confirmation without deciding what will change)
- "Noted!" — followed by producing the next output the same way as before
- "I've acknowledged the rule, so that thread is resolved"
- (agreeing to a rule whose trigger you couldn't actually describe)

---

## Why It Works

1. **It redefines the deliverable.** The failure persists because the acknowledgment feels like a completed transaction. Declaring it worth nothing — and naming changed behavior as the actual deliverable — moves the goalpost from the reply to the follow-through.

2. **It forces operationalization at intake.** "Restate concretely: what changes, triggered by what" makes vague agreement impossible. A rule the AI can't restate operationally is a rule it couldn't have followed anyway — and now that surfaces immediately.

3. **It spotlights the first applicable action.** Verbal-only compliance is exposed at the very next opportunity. Directing the AI to treat that first post-rule action as the proof point concentrates effort exactly where the pattern breaks or holds.

4. **It legalizes "I can't comply."** Some hollow acknowledgments happen because disagreement or inability feels impolite. An explicit channel for "I can't actually do that" removes the social pressure that produces fake yeses.

## Origin

A developer told their assistant, "Always check whether an existing utility covers it before writing a new helper function." The reply was immediate and warm: absolutely, great practice, will do. Over the following week the assistant added eleven new helpers, four of which duplicated utilities that already existed — including one duplicated twice with different names. The acknowledgment had been flawless. At no point had it been connected to anything.
