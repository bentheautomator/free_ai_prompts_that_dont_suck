---
title: Finish Renames Everywhere
slug: finish-renames-everywhere
category: code-quality
tags: [universal, naming, edits]
works_with: all
severity: high
one_liner: "AI renaming a symbol in some places and leaving the old name alive in others"
---

# Finish Renames Everywhere

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from doing partial renames that leave the old name living on in strings, configs, and far-away files.

**[Copy-paste ready version](../../install/finish-renames-everywhere.md)** — just the instruction block, no explanation.

## The Problem

A rename sounds atomic — change `userId` to `accountId` — but it's actually a census. The symbol lives in code references, sure, but also in string literals used for dispatch, JSON keys, API payload fields, database column mappings, environment variable names, test fixtures, mock data, CLI flags, dictionary lookups (`payload["userId"]`), serializer field lists, and a regex someone wrote in 2021. An AI performing a rename updates the references it can see and a few it searches for, then stops — usually right at the boundary where the name stops being a *symbol* and becomes a *string*.

The half-renamed state is nastier than either name alone. Code-level references that were missed fail loudly, which is merely annoying. String-level references fail silently: the event handler listening for `"user.updated"` never fires again because the emitter now sends `"account.updated"`; the dict lookup returns `None` instead of erroring; the API consumer keeps sending `userId` and the server, renamed, ignores it. Dynamic languages and stringly-typed boundaries are exactly where the compiler can't catch the leftovers — and exactly where AI partial renames concentrate.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Finish Renames Everywhere

A rename is not done until the old name returns zero meaningful search hits. NEVER rename a symbol by updating only the references in front of you — a rename is a codebase-wide census, and the references that hide in strings are the ones that break silently.

**When renaming anything:**
- Search the entire repository for the old name *as text*, not just as a code symbol — case-insensitively, and in every file type: source, tests, fixtures, configs, SQL, templates, scripts, CI workflows
- String-form references are the danger zone: event names, dict/map keys, JSON fields, queue and topic names, env var names, CLI flags, `getattr`/reflection lookups, log-parsing patterns. The compiler will not save you here
- Check name *variants*: `userId`, `user_id`, `USER_ID`, `user-id`, and `UserId` are all the same name wearing different casings — a rename must catch every form
- External contracts (API request/response fields, database columns, published event schemas, env vars set in deployment) may be consumed by systems outside this repo — flag these to the user instead of renaming unilaterally; that's a migration, not an edit
- After the rename, run the search again. Every remaining hit of the old name must be deliberate (e.g., a backwards-compatibility shim) and explainable — say what you left and why

**Red flags that you're about to violate this:**
- "I've renamed the function and updated its callers..." (and its strings?)
- "I searched for the symbol and fixed all usages..." (symbol search misses text)
- "The tests will catch any references I missed..."
- "That string just happens to contain the old name, probably unrelated..."
- "The other casing variants are different identifiers..."
- Declaring a rename complete without a final full-text search for the old name

---

## Why It Works

1. **It redefines done as a search result.** "Renamed everywhere" is a feeling; "zero unexplained hits for the old name" is a measurement. The closing search converts completion from claim to evidence.

2. **It targets the symbol/string boundary by name.** The AI's mental model of a rename is symbol-shaped, so it stops where IDE rename tooling stops. Enumerating the string-form hiding places extends the census to where the silent failures actually live.

3. **It forces the casing sweep.** `user_id` and `userId` being "the same name" is obvious to a human and invisible to a literal search. Making variants explicit closes the most common gap in an otherwise honest rename.

4. **It fences off external contracts.** The worst rename outcome is breaking a consumer you can't see. Routing API fields and event schemas to the user converts a potential cross-system incident into a conversation.

## Origin

An assistant renamed an analytics event from `checkout_completed` to `purchase_completed`, dutifully updating the emitting code, the types, and the tests. The data team's pipeline — a different repo — filtered on the old string, as did two marketing automations. Conversion metrics flatlined overnight; an on-call analyst spent half a day ruling out a tracking outage before someone diffed the event names. The events had fired perfectly the whole time, into queries that no longer matched them.
