---
title: Use Existing Constants, Not Literals
slug: use-existing-constants-not-literals
category: code-quality
tags: [universal, constants]
works_with: all
severity: high
one_liner: "AI hardcoding magic values that already exist as named constants"
---

# Use Existing Constants, Not Literals

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from hardcoding literal values that the codebase already defines as named constants.

**[Copy-paste ready version](../../install/use-existing-constants-not-literals.md)** — just the instruction block, no explanation.

## The Problem

The codebase has `MAX_RETRIES = 3` in `config/limits.py`. The AI writes `for attempt in range(3)`. The codebase has `OrderStatus.SHIPPED`. The AI writes `if status == "shipped"`. The values match today, so everything works, every test passes, and the review skims right past it — a literal `3` looks exactly as correct as a literal `3` should.

Then someone changes `MAX_RETRIES` to 5, or renames the status to `"dispatched"` in the enum, and updates every *reference* — which the hardcoded copy, by definition, is not. The AI's literal keeps its old value forever. This is how a codebase ends up with a payment service that retries three times while everything else retries five, or a status comparison that silently stops matching anything. The failure isn't visible at write time, only at change time, which can be months later and assigned to someone who's never seen the file.

AI assistants do this because emitting the value is one token of effort while finding the constant requires a search, and because in training data, standalone snippets hardcode everything. Your codebase is not a standalone snippet.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use Existing Constants, Not Literals

NEVER hardcode a value that the codebase already defines as a named constant, enum, or config entry. A literal that duplicates a constant is a bug with a delay timer: it works until the constant changes, then silently doesn't.

**Before writing any literal that carries meaning — timeouts, limits, retry counts, status strings, role names, error codes, URLs, queue names, currency codes, dimensions:**
- Search for the value itself and for likely constant names (`MAX_`, `DEFAULT_`, `_TIMEOUT`, `Status.`, `Role.`, enum files, `constants.*`, `config.*`)
- If the constant exists, import and use it — even when that means adding an import to a file that didn't have one
- If the codebase compares against an enum, compare against the enum member, never its string value
- If the value appears 2+ times in your own new code and no constant exists yet, define one where the codebase keeps them
- Plain structural literals (`0` for an index start, `1` for an increment, `""` for empty-check) are fine — the rule is about values with domain meaning

**Red flags that you're about to violate this:**
- "It's just a 3, I'll inline it..."
- "The string 'shipped' is what the API returns, so comparing directly is fine..."
- "Importing the constants module for one value feels heavy..."
- "I'll match the value they're using elsewhere..." (matching the value instead of referencing the name)
- "This number won't change..."
- Typing a quoted status, role, or event name without checking whether an enum defines it

---

## Why It Works

1. **It reframes the literal as a delayed bug, not a style nit.** The AI treats hardcoding as cosmetic because the code works at write time. Naming the change-time failure mode makes the cost concrete enough to justify the search.

2. **It catches the subtle variant: matching values instead of referencing names.** The AI often *does* check what value the codebase uses — then copies the value rather than the symbol. The instruction distinguishes those explicitly.

3. **It scopes the rule.** Banning all literals would be noise the AI learns to ignore. Exempting structural literals keeps the rule credible and enforceable for the values that matter.

4. **It kills the import-weight excuse.** "Adding an import for one constant feels heavy" is a real rationalization the model produces; pre-authorizing the import removes it.

## Origin

A feature branch added a session-expiry check with a hardcoded `86400` — one day, in seconds, matching the `SESSION_TTL` constant at the time. A quarter later, security shortened `SESSION_TTL` to four hours. Every code path honored it except the AI-written check, which kept accepting day-old sessions. The gap was found during a pen test, and the writeup's first question was why the same policy lived in two places with two values.
