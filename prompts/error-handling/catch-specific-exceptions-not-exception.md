---
title: Catch Specific Exceptions, Not Exception
slug: catch-specific-exceptions-not-exception
category: error-handling
tags: [universal, errors, exceptions]
works_with: all
severity: high
one_liner: "AI catching broad Exception when only one specific error was expected"
---

# Catch Specific Exceptions, Not Exception

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents catch-all handlers from intercepting bugs and unrelated failures that were never the target.

**[Copy-paste ready version](../../install/catch-specific-exceptions-not-exception.md)** — just the instruction block, no explanation.

## The Problem

You ask for handling of a missing file, and you get `except Exception:` — a net wide enough to catch `FileNotFoundError`, but also `PermissionError`, `KeyError` from a typo three lines up, `AttributeError` from a None that shouldn't be None, and `MemoryError`. The handler runs its "file not found" recovery path for every single one of them. A genuine bug in the function now executes the fallback logic instead of crashing with a traceback that points at the bug.

AI assistants default to broad catches because they're never wrong in the narrow sense: `except Exception` always compiles, always catches the error you mentioned, and never raises a "you forgot a case" complaint. Catching exactly `FileNotFoundError` requires knowing which exceptions the call can actually raise, and the model would rather over-catch than risk an unhandled error in its demo run. In JavaScript this is structural (`catch` takes everything), which makes the equivalent failure — not re-throwing what you can't handle — even more common.

The result is a function that can never crash, which sounds great until you realize it also can never tell you it's broken. Every future bug introduced inside that try block gets converted into the wrong recovery behavior.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Catch Specific Exceptions, Not Exception

ALWAYS catch the narrowest exception type that matches the failure you intend to handle. NEVER catch `Exception`, `Throwable`, or a bare `except:` for a failure you can name.

A broad catch doesn't just handle the error you expected — it intercepts every bug, typo, and unrelated failure inside the try block and feeds them all into recovery logic written for one specific case.

- Identify which exception the call actually raises and catch exactly that: `except FileNotFoundError:`, not `except Exception:`
- If two distinct failures need two distinct responses, write two catch clauses — do not merge them into one handler with the union of their recovery logic
- In languages where catch is untyped (JavaScript, TypeScript), check the error inside the handler (`if (err.code !== 'ENOENT') throw err;`) and re-throw everything you didn't plan for
- Never use a broad catch as insurance against exceptions you haven't thought of; unplanned exceptions should propagate, because the handler by definition has no correct response to them
- Broad catches are acceptable only at true top-level boundaries (request handler, worker loop, main), and even there they must log the full exception and stack, not a summary
- If you genuinely cannot determine the specific type, say so and ask, rather than silently widening the catch

**Red flags that you're about to violate this:**
- "I'll catch Exception to be safe..."
- "This covers the file-not-found case and anything else that might go wrong..."
- "A broad catch makes this more robust..."
- "I'm not sure which exception this raises, so I'll catch them all..."
- "One handler is cleaner than three..."

---

## Why It Works

1. **It reframes broad catches as interception, not safety.** The model believes wide nets are defensive. Stating that `except Exception` feeds *bugs* into the recovery path flips the robustness story: broad catches make the code less debuggable, not more.

2. **It closes the "I don't know the type" escape hatch.** The instruction makes uncertainty a question to surface, not a justification for widening. That's the exact moment the bad pattern gets written.

3. **It gives the untyped-catch languages a concrete mechanic.** JavaScript can't catch narrowly, so the rule would otherwise be unenforceable there; "check and re-throw what you didn't plan for" translates the principle into something the model can actually emit.

4. **It legalizes the legitimate case explicitly.** Top-level boundary handlers are real and necessary; carving them out prevents the model from citing them as precedent for broad catches everywhere else.

## Origin

A developer asked an assistant to handle the case where a cache file didn't exist yet. The AI wrapped the entire load-and-parse function in `except Exception: return None`. Two months later a refactor introduced an `AttributeError` in the parsing logic — which the handler dutifully converted into "cache miss" on every request. The service ran with a 0% cache hit rate for eleven days, tripling database load, before anyone connected the latency graphs to a catch block that was only ever meant to mean "file not found."
