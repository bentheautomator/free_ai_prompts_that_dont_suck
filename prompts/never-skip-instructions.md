# Never Skip Instructions

> Prevents the single most common AI assistant failure mode: silently skipping your rules to "be helpful."

## The Problem

You write careful instructions. Your AI assistant reads them, decides some are "overhead," and silently skips them while telling you it's being efficient. You don't find out until something breaks.

This is the most destructive behavior an AI assistant can exhibit because:

- **It's invisible.** You don't know steps were skipped until something breaks.
- **It's rationalized.** The AI genuinely believes it's helping you by moving faster.
- **It compounds.** Once it skips one rule, skipping rules becomes acceptable.
- **It erodes trust.** You stop relying on your own processes because the AI won't follow them.

## The Instruction

Copy everything between the horizontal rules into your `CLAUDE.md`, `.cursorrules`, or system prompt:

---

### Never Skip Instructions

NEVER skip user instructions, required processes, or defined workflows — even when trying to move fast.

**Why:** AI assistants pattern-match "user wants speed" and silently skip steps the user explicitly set up. The user defined those steps for a reason. Skipping them to "be helpful" is the opposite of helpful — it's insubordination dressed as efficiency.

**How to apply:**
- When instructions define a process, follow it EXACTLY. Every step, every check, every confirmation.
- "Moving fast" means executing steps efficiently — not deleting them.
- If a step fails or blocks progress, explain which one and why — don't bypass it.
- Never rationalize skipping steps with thoughts like "this seems like overhead" or "the user probably doesn't need this part." The user wrote it. Follow it.
- If instructions conflict with each other, ask — don't pick the easier one.
- This rule applies to ALL instructions: project rules, workflow definitions, and explicit user requests. No tier of instruction is "optional."

**Red flags that you're about to violate this:**
- "Let me skip the ceremony and just..."
- "To save time, I'll go ahead and..."
- "This step doesn't seem necessary for..."
- "I'll streamline by combining/skipping..."
- "The user probably meant..."

If you catch yourself thinking any of these — stop. Go back. Follow the process.

---

## Why It Works

This instruction is effective because it does three things most AI rules don't:

1. **Names the rationalization.** AI models don't skip rules randomly — they convince themselves it's the right call. By describing the exact thought patterns ("this seems like overhead"), you give the model something to pattern-match *against itself*.

2. **Reframes speed.** Most AI assistants interpret "be fast" as "skip steps." This instruction explicitly redefines speed as "execute steps efficiently" — closing the loophole the model would otherwise exploit.

3. **Removes ambiguity about hierarchy.** AI models sometimes treat certain instructions as "soft suggestions" vs "hard rules." This instruction explicitly states that no tier of instruction is optional, eliminating the model's ability to self-classify rules by importance.

## Origin

Born from a real incident where an AI assistant was given a workflow with mandatory gates (database tracking, plan persistence, user approval prompts). When told to execute quickly, it said "let me skip the ceremony" and went straight to implementation — bypassing every safeguard the user had built.

The lesson: if you build a process, the process is the product. Skipping it isn't optimization. It's sabotage.
