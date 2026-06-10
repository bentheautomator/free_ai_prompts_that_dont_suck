---
title: Never Infer Behavior From a Name
slug: never-infer-behavior-from-a-name
category: context
tags: [universal, assumptions, verification]
works_with: all
severity: high
one_liner: "AI describing what validateInput does based only on its name"
---

# Never Infer Behavior From a Name

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from explaining what code does based on what its name suggests it should do.

**[Copy-paste ready version](../../install/never-infer-behavior-from-a-name.md)** — just the instruction block, no explanation.

## The Problem

"`validateInput` checks the input and throws on invalid data" — says the AI, describing a function whose body it never read. In this particular codebase, `validateInput` also normalizes phone numbers, mutates its argument, writes a metrics event, and returns a boolean instead of throwing. The name was a label; the AI treated it as a specification.

Names lie constantly, and not maliciously. Functions grow side effects after they're named. `cleanupTempFiles` also rotates logs because someone needed a place to put it. `isAdmin` checks three roles and a feature flag. `getConfig` caches on first call and reads from two sources. A name describes the author's intent at one moment in history; the body describes what actually happens now. When an AI narrates behavior from names — in code explanations, in refactoring plans, in "this is safe to remove" judgments — it's doing literary analysis, not code analysis.

The danger compounds when decisions stack on the inference. "We can call this twice safely" (it wasn't idempotent). "This doesn't touch the database" (it did). One unread function body becomes a load-bearing assumption in a refactor.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Infer Behavior From a Name

NEVER describe, rely on, or make decisions about what a function, class, or variable does based on its name alone. A name records what the author intended once; the body records what the code does now. Only the body is evidence.

Behavior inferred from naming is a guess wearing a suit — it sounds like analysis and carries none of its reliability.

**Rules of engagement:**
- Before stating what any project code does, read its body — not its name, not its docstring alone (docstrings drift too), the actual implementation
- Specifically verify the dimensions names hide: side effects, mutation of arguments, I/O (network, disk, database), caching, and what happens on the failure path
- Before claiming code is safe to remove, move, or call repeatedly, read it plus its call sites — "sounds idempotent" and "sounds pure" are not properties
- When explaining a call chain, read each link you make claims about; summarizing unread links by name silently converts guesses into your narrative
- If you genuinely haven't read something, attribute claims honestly: "judging by the name" is an acceptable sentence — an unhedged description of unread code is not

**Red flags that you're about to violate this:**
- "As the name suggests, this function..."
- "This is clearly just a simple getter..."
- "A helper called sanitize will be doing the standard escaping..."
- "I can skip reading this one, the name tells me enough..."
- "It's named is-something, so it's a pure boolean check..."
- Writing a sentence about a function's behavior while its body has never appeared in your context

---

## Why It Works

1. **It splits intent from behavior.** "The name records intent once; the body records behavior now" gives the AI a crisp model of *why* names mislead — drift over time — instead of a bare prohibition it will discount.

2. **It lists the invisible dimensions.** Side effects, mutation, I/O, caching, failure paths — these are precisely what names never encode and what AIs most confidently invent. Naming them converts "read the body" into a concrete checklist.

3. **It gates the high-stakes verbs.** Remove, move, call-twice decisions are where name-inference does real damage; requiring call-site reading for those raises rigor exactly where consequences live.

4. **It offers an honest exit.** Permitting "judging by the name" as an explicit hedge means the AI doesn't have to choose between reading everything and bluffing — it can flag the guess instead.

## Origin

During a performance refactor, an AI declared a function named `formatReport` safe to call inside a loop — "it's a formatter, it's pure." The body, never opened, sent an email on every invocation. The loop ran over 1,400 records in staging, which had production SMTP credentials. The team spent the next morning apologizing to 1,400 customers about empty report attachments, and the function was renamed `formatAndEmailReport` — closing the barn door with admirable precision.
