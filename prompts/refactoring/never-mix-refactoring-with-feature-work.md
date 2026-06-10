---
title: Never Mix Refactoring With Feature Work
slug: never-mix-refactoring-with-feature-work
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: high
one_liner: "Stops refactors and feature changes from landing in one unreviewable diff"
---

# Never Mix Refactoring With Feature Work

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from interleaving structural cleanup and behavior changes in a single change, making both impossible to review or revert.

**[Copy-paste ready version](../../install/never-mix-refactoring-with-feature-work.md)** — just the instruction block, no explanation.

## The Problem

"Add rate limiting to this endpoint" comes back as a 400-line diff: the handler has been split into three functions, two helpers were renamed, the config loading was restructured, and somewhere in the middle of all that, rate limiting was added. The reviewer now faces the worst possible artifact: a diff where they can't tell which lines change behavior and which merely move it. They either review every line as if it were a behavior change (slow, exhausting) or skim it (dangerous). Most pick dangerous.

Assistants mix the two because they process the file as a whole. While implementing the feature, the model notices ugliness and fixes it in the same breath, the way it would in a single forward pass of generation. It has no native concept of "this belongs in a different commit" unless told.

The cost shows up later, too. When the feature turns out to be buggy and needs reverting, the revert also undoes the refactor, and untangling them at revert time, during an incident, is the most expensive possible moment to do it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Mix Refactoring With Feature Work

NEVER combine structural refactoring and behavior changes (features, bug fixes) in the same change. One change does one or the other, never both.

Mixed diffs cannot be reviewed (no way to tell moved lines from changed lines) and cannot be reverted (undoing the bug undoes the cleanup).

- If implementing a feature requires restructuring first, do it as two sequential changes: first a pure refactor that changes no behavior, then a feature change against the cleaned-up code. Say explicitly which phase you're in.
- Refactor-first is the normal order: "make the change easy, then make the easy change."
- While doing feature work, do not rename, reformat, extract, or reorganize anything beyond the minimum the feature requires. Note the cleanup you wanted and propose it as a follow-up instead.
- While doing refactor work, do not add parameters "we'll need later," new options, new validation, or any capability that didn't exist before.
- If asked to do both in one request ("clean this up and add X"), still deliver them as two separately reviewable steps, refactor first, and label each.
- Each phase must leave the code in a working state: compiling, tests green.

**Red flags that you're about to violate this:**

- "Since I'm already editing this function for the feature, I'll tidy it up too."
- "These renames are trivial; they won't make the diff harder to read."
- "It's more efficient to restructure and add the feature in one pass."
- "The reviewer will appreciate that I cleaned this up along the way."
- "Splitting this into two changes feels like bureaucracy."

---

## Why It Works

1. **It gives the model a sequencing template, not just a prohibition.** "Refactor first, then feature, as two changes" is an actionable plan, so the model's urge to clean up gets a destination instead of a denial.
2. **It defines mixing from both directions.** Models smuggle features into refactors ("we'll need this parameter") as often as refactors into features; covering both halves closes the symmetric loophole.
3. **The phase announcement creates an audit trail.** Forcing the model to declare "this is the refactor phase" makes a behavior change inside that phase a detectable contradiction rather than an invisible drift.

## Origin

A developer asked for pagination on a list endpoint. The assistant delivered it inside a diff that also reorganized the entire query-building layer. The pagination had an off-by-one that dropped the last item of every page; reverting it meant reverting the reorganization that three newer commits had already built on. The team spent an evening hand-crafting a surgical revert that the right commit structure would have made a one-liner.
