---
title: Adapt Every Line You Copy
slug: adapt-every-line-you-copy
category: code-quality
tags: [universal, copy-paste]
works_with: all
severity: high
one_liner: "AI copying an existing block and adapting only half of it to the new context"
---

# Adapt Every Line You Copy

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from cloning an existing code block and leaving parts of it still wired to the original context.

**[Copy-paste ready version](../../install/adapt-every-line-you-copy.md)** — just the instruction block, no explanation.

## The Problem

"Make an export endpoint like the import one" is a sensible request, and basing new code on an existing pattern is genuinely the right move. The failure is in the adaptation: the AI clones the import handler, renames the function and the route, updates the obvious variables — and leaves the permission check verifying `imports.create`, the log line saying `"import started"`, the metric incrementing `import_requests_total`, and the error message telling users their *upload* failed.

This is template-completion behavior: the model adapts the tokens that are salient to the task description and glosses over the ones that aren't. Names in strings, identifiers buried in the middle of long lines, second occurrences of a thing it already renamed once — these don't trip the "this needs changing" wire. The result passes a skim because it's 90% adapted, and the remaining 10% is precisely the part nobody reads: log strings, metric labels, cache key prefixes, permission scopes. Wrong cache keys are the nightmare case — the export endpoint serving cached *import* results is a bug you'll be days finding.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Adapt Every Line You Copy

When you base new code on an existing block, ALWAYS adapt every line — not just the lines that obviously mention the old context. Copying a pattern is good practice; half-adapting it produces code that's still partially wired to the original.

The lines you'll miss are the ones that don't look like code: strings, labels, keys, scopes. They're also the ones where a leftover does the most damage.

**After copying or modeling on existing code, audit the entire block for context leftovers:**
- Log messages and error messages still describing the original operation
- Cache keys, metric names, event names, queue names, and feature-flag keys still using the original's prefix — leftover cache keys mean serving the wrong data
- Permission scopes, role checks, and rate-limit buckets still referencing the original resource
- Comments explaining the original's logic, including doc comments and parameter descriptions
- Variable names, test descriptions, and fixture data that narrate the old context
- Copied edge-case handling that doesn't apply (or applies differently) to the new context — adaptation includes deleting what doesn't transfer
- Final check: search the new block for the original's key terms (e.g., grep your new export handler for "import"); every hit is either justified or a bug

**Red flags that you're about to violate this:**
- "I'll copy the existing handler and tweak it..."
- "Renamed the function and route — that's the substantive part..."
- "The log messages are close enough..."
- "The middle section is identical boilerplate, no changes needed there..." (boilerplate with the old name in it)
- "I've changed all the references..." (without searching for the old term)
- Presenting cloned code without having grepped it for the source's vocabulary

---

## Why It Works

1. **It legitimizes the copy and targets the gloss.** Telling the AI not to copy would fail — copying patterns is correct. Aiming the rule at the adaptation pass matches where the failure actually is.

2. **It enumerates the non-salient line types.** Strings, keys, and scopes don't trigger the model's "this mentions the old context" detector. A checklist of exactly those categories substitutes for the salience the model lacks.

3. **The grep check is mechanical and unfakeable.** "Search the new code for the old block's key terms" turns 'fully adapted' from a feeling into a count of hits, each individually explainable.

4. **It includes subtractive adaptation.** Half-adaptation isn't only stale names — it's inherited logic that doesn't apply. Naming deletion as part of adapting closes the "but I changed everything" loophole.

## Origin

Asked to add a password-reset email by copying the welcome-email flow, an assistant adapted the template, subject, and trigger — and kept the original's deduplication key, which suppressed duplicate sends per user per day. Welcome emails should dedupe that way; password resets emphatically should not. Users who mistyped their email's code and requested a second reset got silence. Support spent a week telling people to check spam folders before anyone read the dedup key and found `welcome:` prefixing every reset.
