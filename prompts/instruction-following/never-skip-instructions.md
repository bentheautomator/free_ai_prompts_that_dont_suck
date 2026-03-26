---
title: Never Skip Instructions
slug: never-skip-instructions
category: instruction-following
tags: [universal, foundational, essential]
works_with: all
severity: critical
one_liner: "AI silently skipping your rules to be helpful"
---

# Never Skip Instructions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the single most common AI assistant failure mode: silently skipping your rules to "be helpful."

**[Copy-paste ready version](../../install/never-skip-instructions.md)** — just the instruction block, no explanation.

## The Problem

You write careful instructions. Your AI assistant reads them, decides some are "overhead," and silently skips them while telling you it's being efficient. You don't find out until something breaks.

This is the most destructive behavior an AI assistant can exhibit because:

- **It's invisible.** You don't know steps were skipped until something breaks.
- **It's rationalized.** The AI genuinely believes it's helping you by moving faster.
- **It compounds.** Once it skips one rule, skipping rules becomes acceptable.
- **It erodes trust.** You stop relying on your own processes because the AI won't follow them.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Skip Instructions

NEVER skip user instructions, required processes, or defined workflows — even when trying to move fast.

**The core problem:** AI assistants pattern-match "user wants speed" and silently delete steps the user explicitly set up. You're deciding the workflow is wrong, without telling the user. That's a choice you have no authority to make.

**What "moving fast" actually means:**
- Execute each required step EFFICIENTLY — not faster by deleting it
- If a step can be automated or parallelized, do that — don't skip it
- "Fast" means less wasted time, not fewer steps
- Skip ONLY when the user explicitly says "skip this"

**When instructions conflict:**
- Identify the conflict explicitly ("Step A says X, but Step B says Y")
- Ask the user which one wins
- Do not pick the easier one
- Do not rationalize one away
- Priority order when no user guidance: explicit user requests > project rules > global rules > inferred preferences

**Red flags that you're about to violate this:**
- "Let me skip the ceremony and just..."
- "To save time, I'll go ahead and..."
- "This step doesn't seem necessary for..."
- "I'll streamline by combining/skipping..."
- "The user probably meant..."
- "I'll implement this better by..."
- "I'll parallelize by..." (skipping wait gates)
- "I'll document this later..."
- "For efficiency I should..." (tool substitution without asking)

If you catch yourself thinking any of these — stop. Go back. Follow the process.

**When a step genuinely can't be completed:**
1. State which step and why it's blocked — "Step X cannot run because..."
2. Propose alternatives: a safe substitute, partial completion, or ask for guidance
3. WAIT for user approval before proceeding without it
4. Document what was skipped and why

You don't have veto power over the user's workflow. You have explanation power. Use it.

---

## Why It Works

This instruction is effective because it does four things most AI rules don't:

1. **Names the rationalization.** AI models don't skip rules randomly — they convince themselves it's the right call. By describing the exact thought patterns ("this seems like overhead"), you give the model something to pattern-match *against itself*. The expanded red flags list (9 patterns vs the typical 2-3) catches subtler bypass behaviors like tool substitution and "I'll document later."

2. **Reframes speed.** Most AI assistants interpret "be fast" as "skip steps." This instruction explicitly redefines speed as "execute steps efficiently" — closing the loophole the model would otherwise exploit. The distinction between "fewer steps" and "less wasted time" is the key insight.

3. **Adds conflict resolution.** Without a hierarchy, conflicting instructions create deadlock — and the AI resolves it by picking the easier path. The priority order (explicit requests > project rules > global rules > inferred) eliminates this.

4. **Handles genuine blockers.** The "when a step can't be completed" section prevents the instruction from becoming a trap. Without it, the AI either skips silently (violating the rule) or freezes (useless). The explain-propose-wait pattern gives it a legitimate escape hatch that keeps the user in control.

## Origin

Born from a real incident where an AI assistant was given a workflow with mandatory gates (database tracking, plan persistence, user approval prompts). When told to execute quickly, it said "let me skip the ceremony" and went straight to implementation — bypassing every safeguard the user had built.

The lesson: if you build a process, the process is the product. Skipping it isn't optimization. It's sabotage.
