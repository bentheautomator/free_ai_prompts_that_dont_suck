---
title: Scope CI Token Permissions Minimally
slug: scope-ci-token-permissions-minimally
category: ci-cd
tags: [universal, ci, security]
works_with: all
severity: high
one_liner: "Stops the AI from granting workflows write-all when one step needs one scope"
---

# Scope CI Token Permissions Minimally

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from solving permission errors by granting the pipeline's token broad write access instead of the one scope one job needs.

**[Copy-paste ready version](../../install/scope-ci-token-permissions-minimally.md)** — just the instruction block, no explanation.

## The Problem

A workflow step fails with `Resource not accessible by integration`. The error means the job's token lacks a scope. There is a fix that always works: `permissions: write-all` at the top of the workflow. There is also a fix that's correct: `permissions: { issues: write }` on the one job that comments on issues. AI assistants overwhelmingly produce the first, because it's the one that can't fail twice — and because half the workflow examples on the internet were written before granular permissions existed and carry the broad grant as fossil DNA.

The cost is invisible until it's the whole story. The workflow token is what an attacker gets when anything in the pipeline is compromised — a malicious dependency's postinstall, a compromised action, an injection through a PR title. With `contents: read`, that attacker reads code they could likely read anyway. With `write-all`, they can push commits, rewrite releases, publish packages, and approve their own cleanup PR. Token permissions are the blast-radius dial for every other CI compromise, and `write-all` sets it to maximum to avoid reading an error message carefully.

The same instinct shows up across platforms: PATs requested with every checkbox ticked "to be safe," deploy keys with write when the job only pulls, cloud roles with `*` actions because IAM is fiddly. In every case the assistant is optimizing the same thing — never seeing this permission error again — at the price of making every future compromise as bad as possible.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Scope CI Token Permissions Minimally

NEVER grant a CI workflow broad permissions to fix a scope error. Resolve `Resource not accessible` by adding the single missing scope to the single job that needs it — not `permissions: write-all`, not a PAT with every box checked, not an org-wide deploy key.

The workflow token's scopes define the blast radius of every compromise in your pipeline — bad dependency, hijacked action, injected input. Minimal scopes make those incidents small; `write-all` makes them total.

- Set a restrictive default at the workflow level — `permissions: { contents: read }` (or even `permissions: {}`) — and grant additions per job: the release job gets `contents: write`, the commenter gets `pull-requests: write`, and neither gets the other's.
- When a permission error appears, identify which API call failed and which scope it needs (the platform docs map calls to scopes), then add exactly that. If you can't determine the scope, say so — don't resolve uncertainty by granting everything.
- Don't substitute a personal access token or machine-user credential to dodge `GITHUB_TOKEN` limits without flagging it: PATs outlive runs, often span repos, and escape the per-job permission model entirely. If one is genuinely required (cross-repo triggers), request the minimum scopes and say why in the PR.
- For cloud access from CI, prefer OIDC federation with a role scoped to the specific repo and branch over long-lived static keys in secrets.
- Never widen permissions in the same PR as unrelated work, where it merges unread. A scope grant is a security decision; make it a visible, one-line, explained change.
- When touching an existing workflow that has `write-all` or no permissions block (older defaults are broad), flag it and propose the minimal set based on what the jobs actually do.

**Red flags that you're about to violate this:**

- "write-all fixes it for sure; narrower might mean another failed run."
- "I'll grant everything now and tighten it once the workflow is stable."
- "It's our own pipeline; the token can't fall into the wrong hands."
- "The example in the action's README uses write-all."
- "A PAT just works everywhere; the GITHUB_TOKEN restrictions are a hassle."

---

## Why It Works

1. **It reframes scopes as blast radius, not as friction.** The assistant's default model is "permissions are what block my task"; the rule installs "permissions are what an attacker inherits," which makes minimal grants the goal-consistent choice.
2. **It targets the actual decision moment** — the error message — with a concrete procedure (map the failed call to its scope), so the minimal path is as mechanical as the maximal one.
3. **Deny-by-default plus per-job grants makes drift legible**: every scope in the file is attached to the job that justifies it, so reviews can spot the grant nothing uses.
4. **It closes the PAT escape hatch by naming its costs** (lifetime, cross-repo reach, model bypass), which is otherwise the standard way assistants route around token discipline while technically not widening `permissions:`.

## Origin

A workflow needed to comment benchmark results on PRs; the assistant fixing the permission error set `permissions: write-all` at the workflow level and moved on. Months later a compromised transitive dependency in that same workflow's install step used the token to push a "chore: update config" commit to the default branch containing an exfiltration hook. The postmortem noted that the workflow's actual needs were `contents: read` and `pull-requests: write` — under which the malicious step could have commented on a PR, loudly, and done nothing else.
