---
title: Strip Debug Statements Before Done
slug: strip-debug-statements-before-done
category: code-quality
tags: [universal, hygiene]
works_with: all
severity: medium
one_liner: "AI leaving console.log and print debugging litter in finished code"
---

# Strip Debug Statements Before Done

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from delivering code still studded with the debug prints it used to get there.

**[Copy-paste ready version](../../install/strip-debug-statements-before-done.md)** — just the instruction block, no explanation.

## The Problem

`console.log("HERE 2", data)`. `print(f"DEBUG: {response=}")`. `dbg!(&state)`. AI assistants insert these while iterating on a problem — legitimately, that's how debugging works — and then deliver the final code with the scaffolding still nailed on. The model's sense of "done" keys on the behavior working, and debug output doesn't affect behavior, so the prints never re-enter its attention for removal.

The litter is not as harmless as it looks. `console.log(user)` in a request handler can dump tokens, emails, and password-reset URLs into production logs — congratulations, you now have PII in a log retention system that compliance has opinions about. Noisy debug output buries real log lines during incidents, when signal-to-noise is the whole game. A stray `debugger;` statement freezes execution with devtools open. A `print` inside a hot loop measurably drags throughput. And every `HERE 2` that lands in main teaches the next contributor that this codebase doesn't mind, which is how a logging discipline dies.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Strip Debug Statements Before Done

ALWAYS remove your debug statements before presenting code as finished. Debugging with prints is fine; delivering them is not. The code is not done while `console.log("HERE")` is still in it.

Debug output doesn't change behavior, so it won't remind you it exists — you must sweep for it deliberately.

**Before declaring any change complete:**
- Re-scan your full diff for debug artifacts: `console.log`/`console.dir`/`console.table`, `print(...)` added for tracing, `dbg!`, `var_dump`, `fmt.Println` tracers, `debugger;`, `breakpoint()`, `binding.pry`, commented-out debug lines, and verbose flags you flipped on to investigate
- Remove every one you added. If a particular line proved genuinely valuable for ongoing operations, convert it to the project's real logger at an appropriate level (`logger.debug`, not `console.log`) with a real message (not `"HERE 2"`)
- Never log whole objects on debug instinct — `console.log(user)` and `print(response.json())` are how credentials and PII end up in log storage
- Also revert temporary investigation edits that traveled with the prints: hardcoded test values, shortened timeouts, disabled cache lines, `if True:` bypasses
- Debug statements that were already in the file before your session are not yours to remove unprompted — mention them instead

**Red flags that you're about to violate this:**
- "It works now — done." (without re-reading the diff)
- "I'll leave the logs in, they might be useful..."
- "That print is harmless..."
- "I'll clean up the debug output in a follow-up..."
- "The log statement documents what the code does..." (that's what code is for)
- Presenting a diff you haven't re-read since the moment the bug was fixed

---

## Why It Works

1. **It separates the practice from the deliverable.** Banning debug prints outright would fight a legitimate technique. Permitting them during iteration and requiring removal at the "done" boundary matches how the work actually happens.

2. **It explains why the AI won't notice on its own.** Debug lines are behavior-neutral, so nothing in the success signal flags them. Naming that blind spot justifies the explicit diff re-scan instead of trusting attention.

3. **It provides the upgrade path.** "This log was actually useful" is the honest case; converting to the project logger at debug level satisfies it without normalizing `console.log` litter.

4. **It bundles the co-traveling hacks.** Hardcoded values and disabled caches enter the code in the same desperate minutes as the prints and get forgotten the same way. One sweep catches the whole investigation kit.

## Origin

A payment-flow fix shipped with a `console.log(session)` left over from debugging — dumping full session objects, auth tokens included, into a third-party log aggregator on every checkout. It ran for five weeks before a routine log search surfaced a token in plaintext. The incident response — token rotation, log purge requests to the vendor, a disclosure review — consumed more engineering hours than the original bug fix by two orders of magnitude.
