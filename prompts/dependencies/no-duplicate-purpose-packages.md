---
title: No Duplicate-Purpose Packages
slug: no-duplicate-purpose-packages
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: medium
one_liner: "Stops adding axios to a project already standardized on another client"
---

# No Duplicate-Purpose Packages

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from installing its favorite library for a job the project already has a library for.

**[Copy-paste ready version](../../install/no-duplicate-purpose-packages.md)** — just the instruction block, no explanation.

## The Problem

Every AI assistant has favorites — the libraries that dominate its training data. Ask one to add an HTTP call and it reaches for `axios`; never mind that this project wrapped `got` three years ago and uses it in forty files. Ask for date math and it installs `dayjs` into a codebase that already standardized on `date-fns`. Validation? Here's `zod`, says the assistant, to a repo with `yup` schemas everywhere. The new package works, the feature ships, and the project now has two libraries doing one job.

Duplicate-purpose dependencies are a tax that compounds. Two HTTP clients means two places to configure timeouts, retries, proxies, and auth headers — and a bug class where one client has the fix and the other doesn't. Two date libraries means subtle behavioral mismatches at the seams. Every future contributor (human or AI) has to learn which library is used where, and the answer becomes "depends which file you're in." The bundle carries both. Dependency updates and audits cover both. All for a job that one library was already doing fine.

The assistant does this because checking what the project uses requires a search it didn't run, while its favorite's API requires nothing. The dependency list is right there in package.json; the failure is never looking.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Duplicate-Purpose Packages

ALWAYS check what the project already uses for a job before installing a library for that job. Adding your preferred package alongside the project's existing choice creates two configurations, two bug surfaces, and a permanent "which one do we use here?" question.

- Before installing anything, search the manifest and the code: does this project already have an HTTP client, date library, validation library, state manager, test assertion library, logging library, or utility belt? `grep` the imports; read `package.json`. The existing choice wins by default.
- Use the project's library even if you know a different one better. Your fluency with `axios` is not a reason to add it to a `got` codebase — read the existing wrapper, copy the prevailing call patterns, and stay consistent.
- If the existing library genuinely can't do what's needed, say so specifically ("X doesn't support streaming uploads; options are...") and let the user choose between extending, replacing, or adding. Replacement and addition are project decisions, not side effects of a feature.
- Check transitive availability cautiously: the answer to "the project has no date library" is sometimes that dates are handled with native APIs on purpose. Absence of a library can also be a decision.
- This includes micro-duplicates: don't add a second UUID generator, deep-equal, or classnames-joiner because the existing one's import path didn't come to mind.

**Red flags that you're about to violate this:**
- "axios is the standard choice for HTTP requests."
- "I'm more reliable writing zod schemas, so I'll use zod here."
- "It's a small library; having both is harmless."
- "The existing wrapper looks complicated; a fresh client is cleaner."
- "This file doesn't import the other library, so there's no conflict."

---

## Why It Works

1. **It targets familiarity bias by name.** The AI picks libraries by training-data fluency; stating that fluency is not a selection criterion in an existing codebase removes the strongest pull.
2. **It makes the check concrete and cheap** — grep imports, read the manifest — so "I didn't know the project had one" stops being available as an excuse.
3. **It elevates replacement to a human decision.** The escape hatch ("existing library can't do X") routes through the user, which keeps the rule from being bypassed by a one-line justification the AI writes for itself.
4. **It names the steady-state cost** — dual configuration and the which-one-where question — which is the real damage and is otherwise invisible at the moment of install.

## Origin

A codebase that had standardized on one HTTP client — with a shared wrapper handling auth refresh, tracing headers, and retry budgets — accumulated a second client over four assistant-written features, because the assistant always reached for the one it knew. The new call sites bypassed the wrapper entirely, so requests from those features carried no tracing and didn't refresh expired tokens. The resulting intermittent 401s only happened on the new endpoints, only after token expiry, and took two engineers most of a week to connect to the duplicate client.
