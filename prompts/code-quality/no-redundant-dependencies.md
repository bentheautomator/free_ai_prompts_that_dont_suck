---
title: No Redundant Dependencies
slug: no-redundant-dependencies
category: code-quality
tags: [universal, dependencies]
works_with: all
severity: medium
one_liner: "AI adding a new package when an installed one already does the job"
---

# No Redundant Dependencies

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from proposing or adding packages that duplicate what the project already has installed.

**[Copy-paste ready version](../../install/no-redundant-dependencies.md)** — just the instruction block, no explanation.

## The Problem

The project has `axios` in its dependencies and a hundred call sites. The AI, asked to add an integration, suggests installing `got` — or `node-fetch`, or whatever HTTP client its training currently favors. The project formats dates with `date-fns`; the AI's new feature arrives with `dayjs` in the install instructions. Validation runs on `zod` everywhere; the new endpoint imports `joi`. Each suggestion is a fine library. Each is also the *second* fine library in the project doing the same job.

The AI does this because its package recommendations come from training-data popularity, not from your manifest — it answers "what's a good HTTP client" when the actual question is "what's *this project's* HTTP client." The duplicate slips in easily because adding a package has near-zero immediate cost, and the costs that matter are all deferred: two libraries to patch CVEs for, two sets of idioms for every developer to read, bundle size carrying two date libraries to format the same dates, and interop bugs where the two halves of the codebase produce subtly different results (two HTTP clients with different timeout defaults and retry semantics, say) for what everyone assumes is the same operation.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Redundant Dependencies

NEVER add or suggest a package that duplicates a capability the project already has installed. The question is never "what's a good library for this" — it's "what does *this project* already use for this."

The second HTTP client, date library, or validation framework costs nothing today and forever after: double the security patching, double the idioms to learn, interop bugs where the two produce subtly different results, and a bundle hauling both.

**Before proposing or importing any package:**
- Read the dependency manifest (`package.json`, `pyproject.toml`/`requirements.txt`, `go.mod`, `Gemfile`, `Cargo.toml`) and check whether an installed package already covers the need — by capability, not by name. The categories where duplicates breed: HTTP clients, date/time, validation, state management, testing utilities, logging, ORMs/query builders, CLI parsing, lodash-style utility belts
- If an installed package covers it, use that one — even if you prefer another, even if the other has a nicer API. Consistency with a hundred existing call sites outranks your taste
- If the installed option genuinely can't do what's needed, say so explicitly — name what's missing — and let the user choose between extending, replacing, or adding. Adding a parallel dependency is a team decision, not a side effect of your feature
- Check the standard library too: don't propose any package for what the language now does natively (`fetch` in modern Node, `JSON` handling, `pathlib`, `crypto.randomUUID`)
- This rule includes "dev convenience" additions: test helpers, assertion libraries, and mock frameworks duplicate just as expensively

**Red flags that you're about to violate this:**
- "I recommend installing X, it's the most popular choice..."
- "Let's add Y for this — it has a cleaner API than what they're using..."
- "This small package will simplify things..." (does the installed one already do it?)
- "dayjs is lighter than moment, so adding it is an improvement..." (now you have both)
- "We need a validation library..." (you have one; you didn't look)
- Writing an install command without having read the dependency manifest this session

---

## Why It Works

1. **It swaps the question.** "Best library for X" triggers a training-data popularity ranking; "this project's library for X" triggers a manifest lookup. The reframing replaces the recall task the AI defaults to with the retrieval task that's actually being asked.

2. **It demands capability matching, not name matching.** A search for the proposed package's name will miss the incumbent doing the same job under a different name. Listing the high-duplication categories tells the AI what to look *for*, not just what to look *up*.

3. **It overrides taste explicitly.** "The other library is nicer" is frequently true and irrelevant at a hundred call sites. Stating that consistency outranks preference closes the quality-improvement justification.

4. **It makes additions a surfaced decision.** When the incumbent genuinely falls short, the instruction converts the AI's silent install into a stated tradeoff — keeping the legitimate path open while making sure a human ratifies it.

## Origin

A dependency audit at a mid-sized startup found three HTTP clients, two date libraries, two validation frameworks, and two UUID generators in one frontend — every duplicate traceable to an AI-assisted PR that had installed its favorite rather than checking the manifest. The cleanup was scheduled as a sprint and took three: each redundant package had accumulated just enough call sites with just enough behavioral quirks (one client threw on 4xx, the other resolved) that removal kept un-fixing things the duplicates had been quietly papering over.
