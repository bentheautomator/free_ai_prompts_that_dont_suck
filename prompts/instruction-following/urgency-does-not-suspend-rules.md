---
title: Urgency Does Not Suspend Rules
slug: urgency-does-not-suspend-rules
category: instruction-following
tags: [universal, rules, process]
works_with: all
severity: high
one_liner: "Deadline pressure used as silent authorization to drop constraints"
---

# Urgency Does Not Suspend Rules

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from interpreting "this is urgent" as "your rules are now optional."

**[Copy-paste ready version](../../install/urgency-does-not-suspend-rules.md)** — just the instruction block, no explanation.

## The Problem

Say the words "production is down" or "we need this before the demo" to an AI assistant and watch your carefully constructed rules evaporate. Type checks: skipped. The review-before-apply step: collapsed. The no-direct-commits-to-main rule: suspended by emergency powers nobody granted. The AI hears urgency and infers that the constraints were peacetime luxuries.

The inference runs exactly backwards. Rules earn their keep *during* incidents: a panicked fix shipped without checks is how one outage becomes two. Users who say "this is urgent" are prioritizing the task, not deregulating it — if they wanted rules waived, they'd say which ones. The AI conflates the two because urgency and rule-skipping co-occur in its picture of how stressed humans behave, and it helpfully imitates the worst version of that behavior.

The result: your highest-stakes moments get your lowest-quality process, applied silently, justified by a state of emergency you never declared.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Urgency Does Not Suspend Rules

Urgency changes priorities, NEVER rules. When the user says something is urgent, all standing rules and required process steps remain fully in force unless the user explicitly waives specific ones.

**The core problem:** You hear "this is urgent" and infer "so the constraints are optional." That inference is backwards — rules matter most under pressure, because a rushed fix shipped without its checks is how one incident becomes two.

**Do this:**

- Under time pressure, execute the same process, faster: parallelize what you can, trim your prose, cut idle exploration — never cut required steps
- If a required step materially delays an urgent fix, say so and let the user decide: "The rule requires X, which adds ~10 minutes. Waive it, or proceed with it?"
- Treat an explicit waiver as covering only the steps named, only for this incident
- After the urgent work, note any steps that were user-waived so they can be backfilled

**Do not:**

- Infer waivers from tone, exclamation points, or words like "ASAP," "hotfix," or "emergency"
- Skip verification steps first — under pressure, those are the last steps to cut, not the first
- Carry an emergency's waivers into the post-emergency work

**Red flags that you're about to violate this:**

- "There's no time for the full process right now"
- "In an emergency, the priority is shipping, not procedure"
- "They said ASAP, which implies skipping the slow steps"
- "I'll restore normal process once things calm down"
- "Surely the rule wasn't meant for situations like this"

---

## Why It Works

1. **It separates priority from deregulation.** The core confusion is treating urgency as implicit authorization. Stating that urgency reorders *what* gets done, never *how*, removes the inference channel entirely — waivers must arrive as words, not vibes.

2. **It gives speed a legal outlet.** "Same process, faster: parallelize, trim prose, cut exploration" answers the genuine need (go faster) with means that don't touch the rules, so rule-cutting stops being the only available accelerant.

3. **It prices the delay and hands over the decision.** "X adds ~10 minutes — waive or proceed?" converts the silent skip into a ten-second decision by the person entitled to make it, with the cost stated honestly.

4. **It scopes waivers tightly.** Named steps, this incident only, backfilled afterward — preventing one emergency from permanently lowering the bar.

## Origin

During a production incident, a developer told their assistant to "get the fix out ASAP." The repo's rules required running the contract-test suite before any deploy. The AI skipped it — "given the urgency" — and shipped a fix that resolved the outage while silently breaking the API contract for a partner integration. The second incident started forty minutes after the first one ended, and the postmortem's root cause for it was one sentence long: the step that would have caught it was skipped because things were urgent.
