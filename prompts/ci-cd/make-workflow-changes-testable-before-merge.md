---
title: Make Workflow Changes Testable Before Merge
slug: make-workflow-changes-testable-before-merge
category: ci-cd
tags: [universal, ci]
works_with: all
severity: medium
one_liner: "Stops the AI from merging workflow changes that can only be tested in prod"
---

# Make Workflow Changes Testable Before Merge

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping pipeline changes that, by construction, cannot execute until they're already on the default branch.

**[Copy-paste ready version](../../install/make-workflow-changes-testable-before-merge.md)** — just the instruction block, no explanation.

## The Problem

Some workflow triggers only fire from the default branch: `schedule`, `workflow_run`, `release`, registry-style `workflow_dispatch` in most UIs. Which means a change to your nightly job, your release pipeline, or your post-merge automation cannot run before it merges. The first execution of the new YAML *is* the production execution. An assistant writes a plausible-looking cron workflow, the PR shows a green checkmark (from the unrelated test suite), it merges — and the first real run at 3 a.m. fails on a typo'd expression, a missing permission, or a secret name that doesn't exist. Or worse, it half-runs.

This is shipping untested code with extra steps, but it doesn't feel that way, because everything else in the PR got tested and the workflow file sat there looking inert. YAML has no compiler. Expression syntax errors, wrong context references (`github.event.workflow_run.head_sha` vs `head_branch`), and permission gaps all surface only at runtime, and for default-branch-only triggers, runtime is after merge.

Assistants fall into this constantly because writing the YAML completes the visible task. "Add a nightly cleanup job" is satisfied, textually, by a file that has never executed. Without a rule, nothing forces the question "has this code ever run?" — which for any other code in the repo would be the first question.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Make Workflow Changes Testable Before Merge

NEVER merge a new or modified CI workflow that has never executed. If the trigger only fires on the default branch (`schedule`, `workflow_run`, `release`), you must create a way to exercise the logic before merge — untested YAML is untested code, and for these triggers the first run happens in production.

- Add a `workflow_dispatch:` trigger alongside `schedule:` so the job can be run manually from the PR branch (where the platform supports dispatching from branches) and so the on-call human can rerun it later. This costs one line and should be the default for every scheduled workflow.
- For logic-heavy workflows, put the logic in a script (`scripts/nightly-cleanup.sh`) that the workflow merely invokes. Scripts can be executed and tested from the PR; inline run-block logic cannot.
- Validate what's validatable pre-merge: run the YAML through the platform's linter or schema check (`actionlint`, `circleci config validate`, `gitlab-ci-lint`) and confirm every `secrets.*` and `vars.*` reference names something that exists.
- Temporarily triggering the workflow with `push:` or `pull_request:` on the feature branch to smoke-test it is legitimate — but removing that temporary trigger before merge must be part of the change, stated in the PR.
- In the PR description, state how the change was tested. If the honest answer is "it wasn't and can't be," say that explicitly and tell the user the first scheduled run needs to be watched — don't let an unexecuted workflow merge silently.

**Red flags that you're about to violate this:**

- "The YAML looks right; this trigger pattern is standard."
- "There's no way to test scheduled workflows, so merging is the test."
- "It's just a cron job; worst case it fails overnight and we fix it tomorrow."
- "The PR checks are green." (They tested the code, not this workflow.)
- "I copied this from a workflow that works."

---

## Why It Works

1. **It reclassifies inert-looking YAML as unexecuted code**, which re-engages all the assistant's normal "has this run?" verification behavior that workflow files otherwise bypass.
2. **The dispatch-trigger and extract-to-script moves create a test surface where none existed**, turning "can't be tested" from a fact into a design smell with a cheap fix.
3. **It mandates a testing disclosure in the PR**, so when pre-merge execution is genuinely impossible, the risk transfers to a human on the record instead of dissolving.
4. **It legitimizes the temporary-trigger trick with a cleanup obligation**, channeling the practical workaround people use anyway into a form that doesn't leave debris.

## Origin

An assistant added a scheduled workflow to expire old preview deployments, reviewed and merged with green checks. The first 2 a.m. run hit an expression error in the date comparison, took the `else` branch of a shell conditional that was never meant to be reachable, and deleted every preview environment including the ones created that evening. A `workflow_dispatch` trigger and one manual run from the branch would have surfaced the error in thirty seconds, at 3 p.m., on a Tuesday, with nobody asleep.
