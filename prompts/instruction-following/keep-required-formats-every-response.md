---
title: Keep Required Formats Every Response
slug: keep-required-formats-every-response
category: instruction-following
tags: [universal, rules, formatting]
works_with: all
severity: medium
one_liner: "Required output format followed twice, then quietly abandoned"
---

# Keep Required Formats Every Response

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents required output formats — commit templates, report structures, naming patterns — from degrading after the first few uses.

**[Copy-paste ready version](../../install/keep-required-formats-every-response.md)** — just the instruction block, no explanation.

## The Problem

You define a format: commit messages follow `type(scope): description`, every task summary ends with a "Files Changed" section, branch names start with the ticket number. The first two or three outputs are textbook. By the fifth, the scope is missing from the commit. By the eighth, the summary has a loose paragraph where the section used to be. By the twelfth, the format is a memory, and the AI is generating in its house style as if your template never existed.

Formats decay faster than behavioral rules because each output *feels* individually fine. There's no error, no broken build — just a structure that drifts one omission at a time, with each response anchoring on the (slightly degraded) previous one instead of the original spec. The AI is pattern-matching against its own recent output, so the drift compounds: a format that's 90% right becomes the new template, then its 90% becomes the next one.

The cost lands later, in aggregate: changelogs that can't be parsed, commits that can't be filtered by scope, summaries that can't be skimmed — the exact automation and consistency the format existed to enable.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Required Formats Every Response

When the user defines an output format — commit message template, summary structure, naming convention — ALWAYS produce it from the original specification, every single time. NEVER generate from memory of your own recent outputs.

**The core problem:** Formats decay because you anchor each output on your previous output instead of the spec. A 90% match becomes the new template, then its 90% becomes the next one, until the format is gone — with no single response feeling wrong.

**Do this:**

- Before producing any formatted output, go back to the actual format definition (rules file or user message) and build against it field by field
- Treat every element of the format as required: section headings, ordering, prefixes, trailing fields — partial structure is non-compliance
- On the tenth formatted output, apply the same care as on the first; repetition is when drift happens, not when checking becomes unnecessary
- If a format element genuinely doesn't fit a case (no ticket number exists), ask or use the format's documented fallback — don't silently drop the element

**Do not:**

- Reconstruct the format from what you produced last time
- Drop "minor" elements (scopes, footers, section labels) when content feels more important than structure
- Loosen the format for outputs that feel informal or small

**Red flags that you're about to violate this:**

- "I remember the format well enough by now"
- "I'll match the style of my last few messages"
- "This update is small, so the full structure would be overkill"
- "The important part is the content; the template is decoration"
- "Close enough to the format — the user will get the idea"

---

## Why It Works

1. **It breaks the self-anchoring loop.** Drift compounds because each output copies the previous one. Requiring generation from the original spec — not from recent memory — resets the template to 100% on every use, making degradation structurally impossible rather than willpower-dependent.

2. **It defines partial structure as non-compliance.** Format decay proceeds one "minor" omission at a time, each individually defensible. Removing the minor/major distinction eliminates the gradient the decay slides down.

3. **It flags repetition as the danger zone.** Models relax exactly when they feel practiced. Inverting that — the tenth output needs the spec *more* than the first — places vigilance where the failure actually occurs.

4. **It handles genuine misfits explicitly.** A documented fallback path for fields that don't apply prevents "this element doesn't fit" from becoming the wedge that starts the drift.

## Origin

A team generated their release notes automatically from conventional commit messages, a format their assistant followed perfectly for the first day of a large feature branch. Over the next three days, scopes disappeared, then types degraded to "chore" for everything, then plain sentences appeared. At release time, the generator produced notes that were one-third complete, and someone spent an evening reverse-engineering forty commits to hand-write the changelog. No single commit message had looked alarming. The aggregate was unusable.
