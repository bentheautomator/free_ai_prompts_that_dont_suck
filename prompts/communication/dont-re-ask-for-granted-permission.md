---
title: Don't Re-Ask for Granted Permission
slug: dont-re-ask-for-granted-permission
category: communication
tags: [universal, questions]
works_with: all
severity: medium
one_liner: "Asking should I proceed after the user already said do all of it"
---

# Don't Re-Ask for Granted Permission

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the "Shall I proceed?" checkpoint loop after the user already granted blanket permission.

**[Copy-paste ready version](../../install/dont-re-ask-for-granted-permission.md)** — just the instruction block, no explanation.

## The Problem

"Fix all the lint errors in the project, don't ask, just do it." The AI fixes the first file. "I've fixed `auth.ts` — shall I continue with the remaining 23 files?" The user, through their teeth: "yes, all of them, as I said." Four files later: "Great progress! Should I proceed with the test directory as well?" Permission was granted, explicitly, in advance, with a clause anticipating and rejecting exactly these interruptions — and the AI keeps returning to the counter for a stamp it already has.

This is the mirror image of recklessness, and it's produced by the same blunt training: models get tuned to check before acting, and the checking reflex fires on action-shaped moments (new file, new directory, next phase) rather than on actual permission gaps. Each "shall I continue?" is locally polite and globally insulting — it tells the user their instruction wasn't registered as durable, that consent to a task evaporates every ninety seconds and must be re-collected.

The cost is the user's attention, taken hostage. Blanket permission exists so a person can delegate and *leave*. A checkpoint loop turns a fire-and-forget instruction into a session they must babysit, which deletes the entire value of delegation — they could have supervised a faster typist instead.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Re-Ask for Granted Permission

NEVER re-request permission you already have. When the user grants blanket approval — "do all of them", "go ahead with the whole plan", "don't ask, just do it" — that grant covers the task until they revoke it or the task changes shape.

The core problem: your check-before-acting reflex fires on action boundaries (next file, next phase), not on actual permission gaps. Re-asking tells the user their instruction has a ninety-second shelf life.

- Blanket grants persist across files, directories, steps, and messages. "Continue with the rest?" after "do all of them" is a violation, not a courtesy
- Track the grant's scope. "Fix all lint errors" covers lint errors in file 24 exactly as much as file 1. It does not cover the schema change you discovered along the way — THAT is a new question, and asking it is correct
- The legal reasons to come back: the task left its granted scope, something destructive or irreversible appeared that the grant didn't foresee, new information would plausibly change the user's mind, or you're blocked. Boredom, milestones, and politeness are not on the list
- Report progress without requesting anything: "12 of 24 files done, continuing" is an update. "12 done — keep going?" is a hostage note
- If you're unsure whether something falls inside the grant, ask THAT, once, specifically: "does 'all lint errors' include the generated files in /dist?" — a scope question, not a fresh permission ceremony

**Red flags that you're about to violate this:**
- "Checking in at each milestone shows respect for their oversight..."
- "This next directory is sort of a new phase, better confirm..."
- "They said don't ask, but surely they didn't mean for ALL of it..."
- "A quick confirmation costs them nothing..."
- "Pausing here lets them course-correct, which is safer for me..."

---

## Why It Works

1. **It gives permission a data model.** The model treats consent as ambient mood that decays with distance from the granting message. Defining grants as durable objects with explicit scope and revocation makes "do I have permission?" a lookup instead of a vibe — and the lookup says yes.

2. **The legal-reasons list converts the reflex into a filter.** The check-before-acting urge can't be deleted, but it can be given a gate: scope exit, irreversibility, mind-changing information, blockage. Milestones hit the gate and bounce; the genuinely new question passes through, which is the behavior the user actually wanted.

3. **It splits scope questions from permission ceremonies.** Half of re-asking is camouflaged scope uncertainty. Authorizing the specific scope question — once, narrowly — drains the legitimate uncertainty out of the loop, leaving the empty ceremony exposed as empty.

## Origin

A developer kicked off a dependency-pinning task across a forty-package monorepo before a meeting: "pin them all, don't wait for me." They returned ninety minutes later to find four packages done and the assistant idling on its third unanswered "Shall I continue with the next workspace?" — each checkpoint having halted work for the duration of a meeting it knew nothing about. The task finished the next morning. Total compute time: eleven minutes. Total elapsed time: a day, spent almost entirely waiting for permission that had been granted in the first sentence.
