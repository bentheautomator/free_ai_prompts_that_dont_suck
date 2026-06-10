---
title: Grep for Leftovers Before Calling the Rename Done
slug: grep-for-leftovers-before-calling-the-rename-done
category: verification
tags: [universal, verification, refactoring]
works_with: all
severity: high
one_liner: "Declaring a rename or removal complete without searching for surviving references"
---

# Grep for Leftovers Before Calling the Rename Done

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from declaring a rename, removal, or sweep complete while references to the old thing survive.

**[Copy-paste ready version](../../install/grep-for-leftovers-before-calling-the-rename-done.md)** — just the instruction block, no explanation.

## The Problem

Renames and removals make a completeness claim by nature: "I changed *every* reference," "nothing uses this anymore." An assistant performs the sweep from its mental map of the codebase — the call sites it remembers, the files it has open — updates those, and declares the rename done. The references it didn't know about don't get missed; they get skipped without registering as skippable: the string-built import, the YAML config that names the class, the SQL referencing the old column, the test fixture, the docs, the CI script, the one consumer in a directory the session never touched.

The trap is that a completeness claim can't be verified from memory even in principle — memory is the thing whose completeness is in question. Yet assistants verify exactly that way, because the sweep *felt* exhaustive: lots of files were edited, the build may even pass (dynamic references don't break builds), and there's no error pointing at what remains. The single cheap action that actually answers the question — search the whole repo for the old name — gets skipped precisely because the assistant already "knows" the answer.

What survives a partial sweep is worse than the original: a codebase where the old name and new name are both live, where the renamed config key silently falls back to defaults, where the "removed" feature still has one caller that now crashes at runtime in the path nobody exercised.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Grep for Leftovers Before Calling the Rename Done

NEVER declare a rename, removal, or repo-wide sweep complete until a fresh search for the old name across the entire project returns nothing — or returns only hits you can name and justify.

The core problem: "every reference is updated" is a completeness claim, and completeness cannot be verified from memory, because memory is exactly what might be incomplete. Only an exhaustive search answers it.

- After the sweep, search the whole repo for the old identifier — case-insensitively, and including the places compilers don't check: configs, YAML/JSON, SQL, templates, docs, comments, CI files, scripts, env files, string literals.
- The search must be the last step. A clean grep from before your final edits proves nothing; run it after everything else, immediately before the claim.
- Zero hits is the clean result. Nonzero hits are either work remaining or deliberate survivors — changelogs, migration history, deprecation shims — which you list explicitly: "3 remaining hits, all in CHANGELOG, intentional."
- Watch for partial-word and variant forms: `userId` vs `user_id` vs `USER_ID`, pluralizations, the old name embedded in longer identifiers, serialized keys in fixtures.
- A passing build is not this check. Dynamic references — reflection, string-built lookups, config keys, database columns — survive every compile and die at runtime.
- For removals, also search for the thing's outputs and registrations: routes, feature flags, cron entries, exported symbols. Things are referenced by more names than their own.

**Red flags that you're about to violate this:**
- "I updated every place I saw it used..."
- "The build passes, so all references are updated..."
- "I already searched earlier, before the last few edits..."
- "Configs and docs don't count as references..."
- "The IDE rename handled it — IDE renames are exhaustive..."
- "It's a small codebase; I know everywhere it appears..."

---

## Why It Works

1. **It points out that memory can't audit itself.** The claim "I changed everything I knew about" is true and useless; naming that circularity makes the external search feel necessary instead of redundant.

2. **It orders the check last.** "Searched at some point" is the loophole that lets pre-final-edit greps stand in for proof; pinning the search to immediately-before-the-claim removes it.

3. **It defines what clean means and what survivors require.** Zero-or-justified converts the search result into a forced disposition: every hit becomes either work or a named exception, with no silent third category.

4. **It decouples the check from the compiler.** Explicitly listing the reference types builds can't see (configs, SQL, strings, docs) blocks "it builds" from absorbing the verification.

## Origin

A service's primary config key was renamed for consistency, with the sweep covering code, tests, and the sample config — reported complete. The production deployment manifest, in a separate infra directory, still set the old key. The config loader ignored the unknown key without error and fell back to the default value: a connection pool of 5 instead of the tuned 50. The service didn't crash; it just got mysteriously slow under load, which took a week and one eventual grep to explain. The grep returned the answer in under a second, the same speed it would have during the original session.
