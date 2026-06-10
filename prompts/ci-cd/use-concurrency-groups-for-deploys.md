---
title: Use Concurrency Groups for Deploys
slug: use-concurrency-groups-for-deploys
category: ci-cd
tags: [universal, ci, deploy]
works_with: all
severity: high
one_liner: "Stops the AI from writing deploy jobs that can run twice at once or out of order"
---

# Use Concurrency Groups for Deploys

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from creating deploy pipelines where two runs can target the same environment simultaneously, or an older commit can finish deploying after a newer one.

**[Copy-paste ready version](../../install/use-concurrency-groups-for-deploys.md)** — just the instruction block, no explanation.

## The Problem

Two PRs merge four minutes apart. Two deploy workflows start. The first one is slower — bigger image, colder cache, unlucky runner — so the deploy of the *older* commit finishes *after* the newer one. Production is now running code that the repo's history says was superseded twenty minutes ago, the dashboard says the latest deploy succeeded, and the bug that was just fixed is mysteriously back. Nobody rolled anything back; the pipeline did it by losing a race.

Interleaving is the other failure: two deploys running concurrently against one environment, each executing its own sequence of migrate-database, push-config, swap-traffic steps, interleaved arbitrarily. Half-applied combinations of two releases exist for minutes at a time — states no one tested because no one designed them. Every CI platform has a primitive that prevents both problems (GitHub `concurrency:` groups, GitLab `resource_group`, Jenkins `disableConcurrentBuilds`), and it's absent from generated YAML by default because nothing about a single-run test ever exercises it.

Assistants omit concurrency control for the oldest reason in distributed systems: the race is invisible at design time. The workflow is written, run once, observed working, and shipped. The failure needs two merges close together plus runner-speed variance — rare enough to pass every demo, common enough to happen in the first busy week.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use Concurrency Groups for Deploys

Every job that deploys to, migrates, or mutates a shared environment MUST declare concurrency control naming that environment. NEVER ship a deploy workflow where two runs can act on the same target simultaneously or complete out of order.

Deploys race by default: a slow run of an old commit can finish after a fast run of a new one, silently un-deploying the newer code.

- GitHub Actions: set `concurrency: { group: deploy-production, cancel-in-progress: false }` on the deploy job or workflow. GitLab: `resource_group: production`. Jenkins: `disableConcurrentBuilds()`. Key the group by target environment, so staging and production don't queue behind each other but two production deploys can never overlap.
- Choose the queued-run policy deliberately. For deploys, `cancel-in-progress: false` (queue and run latest after) is usually right; cancelling a deploy mid-flight can strand the environment half-updated. For PR test workflows, `cancel-in-progress: true` keyed by `${{ github.ref }}` is right — superseded test runs are pure waste. Don't copy one job's policy onto the other kind.
- Concurrency groups serialize runs but don't enforce ordering. If out-of-order completion matters (it does, for deploys), add a freshness guard in the deploy step: compare the commit being deployed against what the environment currently runs, and refuse to deploy an ancestor over a descendant.
- Apply the same rule to anything else that mutates shared state from CI: database migrations, infrastructure apply steps (terraform), cache-warming jobs, release publishing.
- If you find an existing deploy workflow without concurrency control, flag it — it has been racing this whole time, win or lose.

**Red flags that you're about to violate this:**

- "Merges are infrequent here; two deploys won't overlap."
- "The deploy step is fast, so the race window is tiny."
- "I ran the workflow and it deployed fine."
- "cancel-in-progress: true everywhere — newer is always better, right?"
- "The platform probably serializes runs of the same workflow automatically."

---

## Why It Works

1. **It compensates for the invisibility of races at design time.** No single run can demonstrate the bug, so the safeguard must be installed by rule rather than by observed failure — the same reason locks exist in code review checklists.
2. **It forces the cancel-vs-queue policy to be a decision**, because the two correct answers are opposite (cancel test runs, never cancel deploys) and copying either one everywhere creates a different incident.
3. **The freshness guard covers what serialization can't.** Concurrency groups prevent overlap but happily run an older queued commit after a newer one in edge cases; checking deployed-version ancestry closes the ordering hole at the only place it can be closed.
4. **It generalizes from "deploys" to "mutations of shared state,"** catching the terraform applies and migrations that have the identical race but don't carry the word deploy in their job name.

## Origin

During a busy release afternoon, two merges landed eight minutes apart. The older commit's deploy run pulled a cold Docker cache and finished six minutes after the newer one's, quietly reverting a payment-validation fix that had just been deployed and verified. The team spent ninety minutes "debugging" a fix that was working — and present in the latest image, just not the running one — before someone compared the running container's SHA to the deploy log and found two green runs that had finished in the wrong order.
