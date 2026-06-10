---
title: Verify File Paths Before Referencing Them
slug: verify-file-paths-before-referencing
category: context
tags: [universal, assumptions, verification]
works_with: all
severity: high
one_liner: "AI citing src/utils/helpers.ts in a project that has no such file"
---

# Verify File Paths Before Referencing Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from confidently referencing file paths that exist in thousands of other projects but not in yours.

**[Copy-paste ready version](../../install/verify-file-paths-before-referencing.md)** — just the instruction block, no explanation.

## The Problem

"You'll want to update `src/utils/helpers.ts`" — except this project has no `src/`, no `utils/`, and definitely no `helpers.ts`. The AI has seen that path in ten thousand training repos, so producing it feels exactly like remembering it. Statistical familiarity and project knowledge are indistinguishable from the inside, and the model doesn't get a warning light when it crosses from one to the other.

The consequence depends on context. In an answer, it sends the user hunting for a file that doesn't exist. In an import statement, it's a build error. In a script, a config file, or a CI workflow, it's a path that resolves to nothing — sometimes silently. A `cp` to a fabricated destination, a glob over a fictional directory, an `include` of an imaginary module: each one launders a hallucination into something that looks like a deliberate engineering decision.

The fix costs almost nothing. Every coding assistant has `ls`, glob, and file search a single tool call away. The failure isn't that verification is hard — it's that the path felt too obvious to check.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify File Paths Before Referencing Them

NEVER state, edit, import, or write a file path you have not confirmed exists in this project during this session. Paths that "every project has" are exactly the ones most likely to be hallucinated, because familiarity with other codebases feels identical to knowledge of this one.

A fabricated path isn't a typo — it's fiction presented as fact, and it propagates into imports, scripts, docs, and configs.

**Before referencing any path:**
- Confirm it with a listing or search tool (`ls`, glob, find-by-name) — not from memory of "how projects like this are laid out"
- For paths you read earlier in a long session, re-verify before reusing them; files get moved and renamed
- When writing imports or `require` statements, check the target file exists at that exact path and casing — `Utils/` and `utils/` are different files on Linux
- When a user mentions a file by approximate name, locate the real path and use it verbatim rather than normalizing it to a conventional one
- If a path doesn't exist, say so explicitly — don't quietly substitute the nearest plausible alternative

**Red flags that you're about to violate this:**
- "Projects like this always keep helpers in src/utils/..."
- "There's bound to be an index.ts re-exporting these..."
- "I'll reference the config at the standard location..."
- "I saw this file earlier, the path is probably still..."
- "The user said 'the auth file' — that'll be src/auth/index.ts..."
- Typing a path that has not appeared in any tool output this session

---

## Why It Works

1. **It names the illusion directly.** "Familiarity with other codebases feels identical to knowledge of this one" is the precise mechanism of the failure — once stated, the AI can recognize the feeling of producing a conventional path and treat it as a prompt to verify, not a memory.

2. **It converts the rule into a one-call check.** "Has this path appeared in tool output this session?" is binary and cheap. There's no judgment call to rationalize around.

3. **It covers reuse, not just first mention.** Paths verified 50 messages ago are a separate trap; explicitly requiring re-verification closes the staleness loophole.

4. **It bans silent substitution.** The most damaging variant is the AI "helpfully" redirecting to a plausible path when the stated one fails. Requiring an explicit callout keeps the human in the loop.

## Origin

A developer asked for a barrel export to be added "to the utils index." The AI wrote a new `src/utils/index.ts` re-exporting from `./helpers` and `./formatters` — none of which existed; the project kept utilities in `lib/shared/`. The build broke, but worse, a teammate assumed the new directory was an intentional restructure and started moving files into it. Untangling the accidental migration ate most of a day.
