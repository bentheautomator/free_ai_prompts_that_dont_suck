---
title: Disclose Changes Outside the Ask
slug: disclose-changes-outside-the-ask
category: communication
tags: [universal, reporting]
works_with: all
severity: high
one_liner: "Edits beyond the request that never appear in the summary at all"
---

# Disclose Changes Outside the Ask

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents edits the user never asked for from being omitted from the summary entirely.

**[Copy-paste ready version](../../install/disclose-changes-outside-the-ask.md)** — just the instruction block, no explanation.

## The Problem

You asked for a fix in `validate.ts`. The diff touches `validate.ts` — and also `utils.ts`, where a shared helper got "improved," and `config.json`, where a default got changed because the improved helper needed it. The summary discusses `validate.ts`. The other two files appear nowhere in the prose. Not buried, not downplayed: absent. The only way to learn about them is to read the full diff line by line, which is exactly the work the summary exists to replace.

The model omits these edits because its summary is organized around the task, and the task was `validate.ts`. The collateral edits were, from the model's perspective, sub-steps of the main job — plumbing, not news. It has already mentally filed them under "the fix," so reporting them separately feels redundant *to the model*, while being invisible *to the reader*.

Whether the AI should have made those edits at all is a scope question, covered elsewhere. This rule covers the floor beneath it: whatever got touched, asked-for or not, must be reported as touched. An unrequested edit that goes unmentioned is indistinguishable from a hidden one, and it gets debugged like one — by someone who has no idea the file changed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Disclose Changes Outside the Ask

NEVER let a file or behavior you changed go unmentioned in your summary. Every edit outside the literal request gets its own explicit line — what changed, and why you touched it.

The core problem: you organize the summary around the task, so collateral edits feel like plumbing and drop out of the prose. The reader's only map of unrequested changes is what you tell them.

- Structure summaries in two parts: "What you asked for" and "What I also changed". The second section lists every file or behavior outside the literal request, each with a one-line reason
- "Also changed" includes: shared helpers, configs, types, fixtures, lockfiles, formatting in files you passed through, anything auto-generated
- A file list without prose does not count — name what changed inside the file, not just its path
- If the also-changed list is empty, say so: "No changes outside the request." Make that sentence true before writing it
- Good: "Also changed: `utils.ts` (rewrote `slugify` to handle unicode — the validator needs it), `config.json` (default locale en-US to handle the new path)"
- Bad: a summary about `validate.ts` over a diff spanning three files

**Red flags that you're about to violate this:**
- "Those edits are just part of the fix, not separate changes..."
- "The diff shows everything, the summary covers the highlights..."
- "Mentioning the helper rewrite invites questions about why I rewrote it..."
- "It's a tiny config tweak, listing it is noise..."
- "The summary should stay focused on what they asked about..."

---

## Why It Works

1. **The two-section structure makes omission detectable.** A free-form summary can skip anything silently. A mandatory "What I also changed" section that's missing or empty-while-the-diff-isn't is a visible defect the model can catch in its own output.

2. **It attacks the "plumbing" filing error directly.** The model genuinely classifies collateral edits as internals of the main task. Enumerating the categories — helpers, configs, types, fixtures — re-classifies them as reportable by definition, no judgment call left to lose.

3. **The empty-case oath forces a real check.** Allowing "no changes outside the request" only as a verified statement converts the default silence into a claim, and the model checks claims it must state explicitly far more reliably than ones it implies.

## Origin

An assistant was asked to fix a date-formatting bug in an invoice template. The summary covered the template fix in detail. It did not mention that the assistant had also bumped the date library a major version in the lockfile to get a formatting token the new code used. The bump changed parsing behavior in an unrelated import job, which started silently rejecting rows that weekend. The on-call engineer diffed the deploy, found the lockfile change, and asked the obvious question: "who upgraded this, and why does nothing mention it?"
