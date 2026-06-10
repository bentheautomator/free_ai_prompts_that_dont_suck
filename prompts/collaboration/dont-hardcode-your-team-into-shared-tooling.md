---
title: Don't Hardcode Your Team Into Shared Tooling
slug: dont-hardcode-your-team-into-shared-tooling
category: collaboration
tags: [universal, teamwork, tooling]
works_with: all
severity: medium
one_liner: "Stops baking one team's paths, names, and needs into tools everyone uses"
---

# Don't Hardcode Your Team Into Shared Tooling

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from baking one team's specific needs — paths, service names, defaults — into tooling that other teams also use.

**[Copy-paste ready version](../../install/dont-hardcode-your-team-into-shared-tooling.md)** — just the instruction block, no explanation.

## The Problem

Shared tooling — the deploy script, the scaffolding generator, the CI template, the local-dev CLI — serves every team. The AI, asked to make the deploy script work for the payments service, makes it work for the payments service: a hardcoded `services/payments` path where a parameter should be, a special case keyed on the service name, a default region that happens to be the one this team deploys to, a check that assumes every service has a `payments-style` health endpoint. The task is done. The tool is now subtly *about* one team.

Other teams pay in two installments. First, the immediate breakage or weirdness: the script now does something payments-specific for everyone, or fails for services shaped differently. Second, the compounding cost: the next person extends the special case rather than fixing it, because that's the pattern now, and two years later the "shared" tool is a pile of team-specific branches that nobody can change without breaking somebody. Hardcoding is how shared tools die — not in one commit, but one defensible special case at a time.

The AI defaults to this because the requesting team's need is the entire visible task, and generalizing costs extra tokens of thought. "Make it work for us" and "make it work" look identical when you can only see one team.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Hardcode Your Team Into Shared Tooling

NEVER bake one team's specifics — paths, service names, regions, defaults, assumptions about project shape — into tooling other teams use. Shared tools must stay generic; team-specific needs go in parameters and config, not in the tool's body.

Every hardcoded special case makes the tool a little more about one team and a little less usable by the rest, and special cases breed special cases.

- When changing a shared script, generator, CI template, or CLI, ask: would this change make sense to a team that isn't mine? If not, it doesn't belong in the shared layer.
- Express team-specific needs through existing extension points: arguments, config files, env vars, per-project overrides. If no extension point exists, add a generic one — don't add an `if (service === "payments")`.
- Don't change shared defaults to your team's values. A default change is a behavior change for every team that relied on the old one.
- Don't encode assumptions about project layout ("every service has `Dockerfile` at the root") that merely happen to be true for the requesting team. Check what shapes actually exist, or fail gracefully with a clear message.
- If the requesting team's need genuinely can't be met generically, say so and propose a team-local wrapper around the shared tool instead of a team-shaped patch inside it.

**Red flags that you're about to violate this:**
- "I'll hardcode the path for now; it's the only service using this anyway."
- "A special case for our service is simpler than adding a parameter."
- "Our region is the sensible default."
- "Every service surely has this file." (You checked one.)
- "I'll generalize it later if another team complains."

---

## Why It Works

1. **It installs the would-another-team-recognize-this test**, a cheap check that catches team-shaped changes before they land in the shared layer.
2. **It routes specificity to extension points**, preserving the architecture that lets one tool serve many teams — parameters absorb variation; special cases accumulate it.
3. **It protects defaults explicitly**, because defaults are the highest-traffic part of any tool and the easiest to quietly bend toward one team.
4. **It offers the wrapper pattern as the escape hatch**, so genuinely unique needs get met without colonizing the commons.

## Origin

A shared deploy script gained a hardcoded pre-deploy step that warmed a cache "because our service needs it" — keyed on nothing, applied to everyone. For most teams it was a silent two-minute delay per deploy. For one team whose service had an endpoint by the same name doing something else entirely, it triggered a partial cache flush in production on every deploy. They chased intermittent latency spikes for a month before reading the deploy script line by line and finding another team's needs hardcoded into their pipeline.
