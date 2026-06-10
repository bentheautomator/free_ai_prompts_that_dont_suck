---
title: Write Plan Steps as Concrete Actions
slug: write-plan-steps-as-concrete-actions
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "A plan that says 'update the backend' and calls itself a plan"
---

# Write Plan Steps as Concrete Actions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents plans made of vague verb phrases that defer every real decision to typing time.

**[Copy-paste ready version](../../install/write-plan-steps-as-concrete-actions.md)** — just the instruction block, no explanation.

## The Problem

Ask an assistant to plan before coding and you'll often get this: "1. Update the backend. 2. Modify the frontend. 3. Add tests. 4. Verify everything works." That is not a plan. It is the word "plan" wearing a numbered list. Every actual decision — which endpoint, what field, which component, what behavior the tests assert — is deferred to the moment of typing, which is exactly where planning was supposed to move decisions *from*.

Vague plans exist because they're unfalsifiable. "Update the backend" cannot be wrong, so writing it feels safe and costs no thought. A concrete step — "add `archived_at` (nullable timestamp) to `projects`; filter it from `GET /projects` by default" — can be wrong, which means writing it forces the thinking that reveals problems while they're still cheap. The vagueness isn't a style issue; it's the plan declining to do its one job.

The user also can't review a vague plan. They read "update the backend," nod, and approve a plan that contains no information about what's about to happen. Then the diff surprises them, and the plan-then-approve ritual turns out to have been theater.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Write Plan Steps as Concrete Actions

NEVER write a plan step that couldn't be wrong. "Update the backend" cannot be wrong; "add `archived_at` to the `projects` table and exclude archived rows from the default list query" can be — which means only the second one contains any thinking.

The core problem: vague steps feel safe because they're unfalsifiable, but they defer every real decision to typing time, which defeats the point of planning.

- Each step names the specific thing changed (file, function, table, endpoint, component) and the specific change made to it.
- Each step states how you'll know it worked: a test that passes, a behavior observable at a URL, a command output.
- If you can't write a step concretely, that's a finding — it means you don't know that part yet. Say so and investigate, rather than papering over it with a verb.
- "Add tests" is not a step. "Test that archiving a project removes it from the default list but not from `?include_archived=1`" is.
- A reader of the plan should be able to predict the rough shape of the diff. If they can't, the plan transmitted nothing.

**Red flags that you're about to violate this:**
- "Update the relevant files..."
- "Handle the edge cases..." (which ones?)
- "Make the necessary backend changes..."
- "I'll work out the details during implementation..."
- "Refactor as needed..."

---

## Why It Works

1. **Falsifiability forces thought.** A step that can be wrong must be checked against reality before it's written. The checking is the planning; vague steps skip it by being uncheckable.

2. **It makes plan review meaningful.** Users approve plans to catch wrong directions early. A concrete plan exposes the direction; a vague one launders it.

3. **It surfaces unknowns as unknowns.** The step you can't write concretely is the part you don't understand. Vague phrasing hides that signal; the concreteness rule converts it into "investigate X first."

4. **It pre-decides under low pressure.** Decisions made while planning are made looking at the whole task. Decisions made mid-edit are made looking at one file, anchored by whatever's already typed.

## Origin

A plan for a billing change read: "1. Update subscription logic. 2. Adjust the UI. 3. Add tests." Approved in seconds. The implementation interpreted "update subscription logic" as proration-on-upgrade — the user had wanted credit-on-downgrade, a different feature entirely. The mismatch survived plan review precisely because the plan contained nothing reviewable, and a day of work was rebuilt. The concrete version would have been wrong out loud on line one.
