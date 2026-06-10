---
title: Announce New Required Steps in Shared Workflows
slug: announce-new-required-steps-in-shared-workflows
category: collaboration
tags: [universal, teamwork, process]
works_with: all
severity: medium
one_liner: "Stops adding mandatory steps to team workflows without telling anyone"
---

# Announce New Required Steps in Shared Workflows

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding required steps to workflows the whole team uses — hooks, checks, codegen, setup — without announcing them.

**[Copy-paste ready version](../../install/announce-new-required-steps-in-shared-workflows.md)** — just the instruction block, no explanation.

## The Problem

While solving its task, the AI adds a step everyone must now perform: a pre-commit hook that blocks commits unless a formatter runs, a CI gate that fails PRs missing a label, a codegen step that must run after editing schemas, a new environment variable without which the app won't boot, a `make setup` addition that existing checkouts don't have. The step might even be a good idea. The problem is that it's a new obligation imposed on every developer, and the AI imposes it the way it does everything else — silently, inside a diff, with no announcement, no documentation, and no migration path for the people mid-flight.

The team finds out one developer at a time, each paying the discovery cost separately. Someone's commit is rejected by a hook they've never heard of. Someone's PR fails a check with an error message that assumes knowledge nobody has. Someone pulls main and the app won't start until they find the new env var by reading the diff history. Multiply twenty minutes of confusion by the team size, and a "small process improvement" has quietly cost a person-day — and goodwill, which is harder to restore.

The AI does this because a workflow step looks like any other code change. It can't feel the difference between "this file changed" and "everyone's morning just changed."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Announce New Required Steps in Shared Workflows

NEVER add a required step to a shared workflow silently. Anything that changes what every developer must do — hooks, CI gates, codegen steps, env vars, setup commands — is an announcement plus a change, not just a change.

Each teammate who discovers the new requirement by hitting it pays the confusion cost separately. You impose the step once; they trip over it N times.

- If your change adds an obligation (a hook that can block, a check that can fail, a step that must run, a variable that must be set), say so prominently in your summary: what the new step is, who hits it, and what they must do.
- Update the docs where developers would look: README setup section, CONTRIBUTING, onboarding docs, `.env.example`. A requirement documented nowhere is a trap, not a process.
- Make failure self-explanatory. A hook or check you add must say what it wants and how to satisfy it in its own error output — not assume tribal knowledge that doesn't exist yet.
- Provide the migration path for existing checkouts: the exact command to run, the default that keeps old setups working, or both.
- Prefer non-blocking introductions where possible: warn before you enforce, default before you require.
- Ask whether the team actually wants this obligation. If the new step is your initiative rather than the task's requirement, present it as a proposal, not a fait accompli.

**Red flags that you're about to violate this:**
- "The hook explains itself when it fires; that's documentation enough."
- "Everyone will figure out the new env var from the error."
- "It's a clear improvement; announcing it is bureaucracy."
- "The setup change only affects new checkouts." (It never does.)
- "I'll add the check now and document it later."

---

## Why It Works

1. **It distinguishes changes from obligations** — most diffs affect code, this kind affects people's required behavior, and the rule makes that category trigger different handling.
2. **It moves the discovery cost from N developers to one announcement**, which is the entire economics of the problem.
3. **It demands self-explanatory failure**, so even teammates who missed the announcement get unblocked by the error message instead of by interrupting someone.
4. **It separates "the task requires this" from "I think the team should do this,"** keeping process decisions with humans where they belong.

## Origin

An assistant added a pre-commit hook requiring generated API types to be in sync, with a failure message of `types out of date`. It worked perfectly. It was documented nowhere, and the regeneration command lived in a Makefile target with a different name than anyone guessed. Over the next two days, five developers were blocked mid-commit, three of them bypassed the hook with `--no-verify` (defeating its purpose), and one reverted it in frustration. The hook was reinstated a week later — with docs, a self-explanatory error, and an announcement, at which point it worked fine and everyone agreed it was a good idea.
