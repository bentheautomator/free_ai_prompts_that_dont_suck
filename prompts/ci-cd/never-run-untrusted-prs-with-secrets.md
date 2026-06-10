---
title: Never Run Untrusted PRs with Secrets
slug: never-run-untrusted-prs-with-secrets
category: ci-cd
tags: [universal, ci, security]
works_with: all
severity: critical
one_liner: "Stops the AI from giving fork PRs a workflow context that holds secrets"
---

# Never Run Untrusted PRs with Secrets

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from using `pull_request_target` or equivalent privileged triggers to execute code from untrusted forks alongside repository secrets.

**[Copy-paste ready version](../../install/never-run-untrusted-prs-with-secrets.md)** — just the instruction block, no explanation.

## The Problem

CI platforms deliberately strip secrets from workflows triggered by fork PRs, because a fork PR is arbitrary code from the internet. This breaks things people want — the coverage uploader needs its token, the labeler bot needs write access — and the platforms provide an escape hatch: GitHub's `pull_request_target`, which runs with full secrets and write permissions in the context of the base repo. Used correctly, it never executes the fork's code. The catastrophic pattern is using it *and* checking out the PR head:

```yaml
on: pull_request_target
steps:
  - uses: actions/checkout@...
    with:
      ref: ${{ github.event.pull_request.head.sha }}
  - run: npm install && npm test
```

That's a vending machine for your secrets: anyone on the internet opens a PR whose `postinstall` script reads the environment, and your deploy keys leave the building. The same hole opens via `workflow_run` chains that execute artifacts or scripts produced by the untrusted run, and via injection — interpolating attacker-controlled strings like PR titles or branch names directly into `run:` blocks (`run: echo "${{ github.event.pull_request.title }}"` executes whatever shell metacharacters the title contains).

Assistants build this pattern because it is the top search result shape for "workflow needs secrets on fork PRs." The error message ("secrets not available") points at the trigger, swapping the trigger fixes the error, and the resulting YAML runs perfectly in every test the assistant can see. The vulnerability has no failing case until someone hostile finds it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Run Untrusted PRs with Secrets

NEVER execute untrusted PR code in a workflow context that has secrets or write permissions. Specifically: never combine `pull_request_target` (or any privileged trigger) with a checkout of the PR's head ref followed by anything that executes PR-controlled code — builds, installs, tests, scripts, or linters with plugin loading.

The platform strips secrets from fork PRs on purpose. Every workaround that restores secrets to attacker-supplied code is the vulnerability, regardless of how standard the YAML looks.

- Default to plain `pull_request` for anything that builds or tests PR code. If a step inside it needs a secret, that step is in the wrong workflow.
- Use `pull_request_target` only for jobs that operate on PR *metadata* without checking out or executing PR code: labeling, commenting, assigning. If the job contains a checkout of `head.sha` or `head.ref`, stop.
- When a result from untrusted code genuinely needs privileges (posting coverage, publishing previews), split it: an unprivileged `pull_request` workflow produces an artifact; a separate `workflow_run` workflow with secrets consumes the artifact as *data only* — validating it, never executing scripts or binaries from it.
- Never interpolate attacker-controlled fields (`pull_request.title`, `head_ref`, issue bodies, commit messages) into `run:` scripts. Pass them through `env:` and reference the environment variable, which the shell treats as data.
- Treat "secrets are not available to fork PRs" as a design constraint to architect around, not an error to make go away. If the user asks for the unsafe pattern, explain the exfiltration path before doing anything.

**Red flags that you're about to violate this:**

- "Switching to pull_request_target fixes the missing-secrets error."
- "Our repo is small; nobody's going to attack our CI."
- "The token only has a few scopes, so the exposure is limited."
- "I saw this exact trigger-plus-checkout pattern in a popular repo."
- "We need coverage upload on fork PRs and this is the only way."
- "It's just echoing the PR title for the log."

---

## Why It Works

1. **It names the precise combination, not just the keyword.** `pull_request_target` is safe by itself; banning the trigger outright would get overridden by legitimate uses, while banning trigger-plus-head-checkout-plus-execution targets the actual hole.
2. **The artifact split satisfies the underlying need lawfully**, so the assistant isn't forced to choose between the feature ("coverage on fork PRs") and the rule — which is when rules lose.
3. **It generalizes execution.** Installs run postinstall hooks, tests run test code, linters load plugins; enumerating these blocks the "I'm only linting it" escape that treats some code execution as not-really-execution.
4. **The env-var rule converts injection from a parsing subtlety into a habit.** "Attacker strings go through env, never into scripts" is mechanical, requires no threat modeling in the moment, and closes a whole class.

## Origin

A maintainer asked an assistant to fix coverage uploads failing on fork PRs with "secret not available." The assistant switched the trigger to `pull_request_target`, kept the head checkout and `npm ci`, and the uploads worked — for everyone. Three weeks later a throwaway account opened a PR titled "fix typo" whose postinstall script shipped the repo's cloud credentials to a paste site, and the first symptom anyone noticed was a compute bill with someone else's workload on it.
