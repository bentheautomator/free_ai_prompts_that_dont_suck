---
title: Follow Team Naming and Structure Conventions
slug: follow-team-naming-and-structure-conventions
category: collaboration
tags: [universal, teamwork, conventions]
works_with: all
severity: medium
one_liner: "Stops the AI from overriding team naming and layout because it knows better"
---

# Follow Team Naming and Structure Conventions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from naming and placing things its own way in a codebase that already has a way.

**[Copy-paste ready version](../../install/follow-team-naming-and-structure-conventions.md)** — just the instruction block, no explanation.

## The Problem

Every team codebase has a grain: services live in `services/<name>/`, handlers are named `handle<Event>`, test files sit next to source as `*.test.ts`, interfaces don't get an `I` prefix, database columns are snake_case. None of this is in a doc. All of it is in the code, visible to anyone who looks. The AI doesn't look — it names things the way its training data names things. So the repo with forty `UserService`-style classes gets a `user_manager.py`, the `__tests__/` project gets a `test/` directory, and the codebase that says `fetchUser` everywhere gets a `getUserData`.

Each deviation is small. The accumulated effect is a codebase you can't navigate by pattern anymore. Grep for `handle*` and miss the handler named `on*`. Look for the test where tests always are and find nothing. Conventions are how a team makes a large codebase predictable — the payoff is that knowing one corner teaches you all of them — and every exception spends that predictability for zero return. Worse, the AI's deviations are usually defensible in isolation ("snake_case is more Pythonic"), which makes them harder to push back on than plain mistakes.

The root cause: the AI treats naming as a style decision it's qualified to make, when in a shared codebase it's a compatibility decision the team already made.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Follow Team Naming and Structure Conventions

ALWAYS name and place new code the way this codebase already names and places similar code. The repo's conventions outrank your defaults, your training data's idioms, and your opinion of what's cleaner.

Conventions make a codebase navigable by pattern. Every deviation breaks someone's grep, someone's mental model, someone's "I know where that lives."

- Before creating any file, function, class, module, or directory, find two or three existing peers and copy their naming scheme, casing, suffix/prefix style, and location exactly.
- Match the local dialect even when it conflicts with the language's general idiom. A codebase that consistently does it "wrong" is consistent, and consistency is the feature.
- Place files where their siblings live: same test layout, same directory depth, same co-location rules. Don't introduce a new directory shape for one file.
- Mirror existing vocabulary: if the codebase says `fetch`, don't introduce `get`/`load`/`retrieve` for the same operation. Same concept, same word, everywhere.
- If you can't find a precedent, say so and pick the closest analogy — don't treat the absence of an exact match as freedom to improvise broadly.
- If a convention seems actively harmful, flag it in your summary as a suggestion. Do not unilaterally "improve" it in your change.

**Red flags that you're about to violate this:**
- "The standard convention in this language is different, so I'll use that."
- "This name is more descriptive than the pattern they use."
- "Their structure is odd; I'll organize my new files more sensibly."
- "It's a new module, so old conventions don't really apply."
- "I'll use the modern naming style; theirs is dated."

---

## Why It Works

1. **It replaces taste with precedent** — "find two peers and copy them" is a mechanical procedure that produces convention-conforming output without requiring the AI to value conformity.
2. **It names the actual asset being protected**: navigability-by-pattern, which is invisible in any single diff but is what conventions buy a team.
3. **It pre-rebuts the strongest rationalization** — "the language idiom says otherwise" — by explicitly ranking local consistency above global idiom.
4. **It channels improvement impulses into flags**, so genuinely bad conventions can still surface without each contributor's change becoming a unilateral style referendum.

## Origin

A Python service used `verb_object` function naming and a flat `handlers/` directory — a structure the team chose deliberately for its code generator. An assistant adding three endpoints decided nested packages and class-based views were "more maintainable," and shipped them that way. The code generator skipped the new endpoints silently, the OpenAPI spec went stale, and a partner team built against documentation missing three routes. The cleanup commit message read: "move new handlers to where everything else already was."
