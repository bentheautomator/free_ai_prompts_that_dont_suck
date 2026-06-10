---
title: Validate Config at Startup, Not First Use
slug: validate-config-at-startup-not-first-use
category: configuration
tags: [universal, config, validation]
works_with: all
severity: high
one_liner: "Stops bad config from hiding until 3am when the code path finally runs"
---

# Validate Config at Startup, Not First Use

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing config that's only checked when the code that uses it finally executes — hours or days after the bad deploy that introduced it.

**[Copy-paste ready version](../../install/validate-config-at-startup-not-first-use.md)** — just the instruction block, no explanation.

## The Problem

The app boots clean. Health checks pass. The deploy is declared good and everyone moves on. Then, at 3am, the nightly export job runs for the first time since the deploy, reaches for `EXPORT_BUCKET_REGION`, finds garbage, and dies — paging whoever's on call to debug a deploy that "succeeded" sixteen hours ago. The person who broke the config is asleep; the deploy that would have caught it instantly is ancient history; the connection between cause and effect has been severed by the gap between *loading* config and *using* it.

AI assistants write lazy validation by default because it's structurally natural: the parse-the-URL code goes next to the use-the-URL code. Each individual choice is defensible. The aggregate result is a system where the answer to "is the configuration valid?" is "run every code path and see," which in practice means "no one knows."

The fix is a boundary rule: validation is a startup activity. A process with invalid config should never get far enough to receive traffic — failing the deploy, loudly, while the person who made the change is still looking at the deploy output.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Validate Config at Startup, Not First Use

ALWAYS validate every config value — presence, type, format, range — during application startup, before the process reports healthy. NEVER let the first validation of a value be the moment a code path finally uses it.

Lazy validation moves the failure from deploy time (cheap, attributable, the author is watching) to first-use time (expensive, 3am, the author is asleep).

- Parse and validate all config in one pass at boot: URLs parse, ports are in range, enums match, durations are positive, referenced files exist. A failure here exits non-zero with a message naming the key and the problem.
- Validate values you can check without side effects eagerly and always. For values that imply a connection (database URL, broker address), at minimum validate the format at startup; verify connectivity in the readiness check.
- Rarely-used config gets the same treatment as hot-path config. The export job's bucket name is exactly the value lazy validation will miss, because "rarely used" means "first use is far from the deploy."
- When you add a new config value, add its validation to the startup pass in the same change — not a check at the call site.
- Don't catch-and-continue during the startup pass. A config error that's logged-and-ignored at boot is lazy validation with extra steps.
- If the project has no startup validation pass, creating one is worth proposing; bolting one more lazy check onto the pile is not.

**Red flags that you're about to violate this:**
- "I'll validate it where it's used, that keeps the logic together."
- "This config is only for the weekly job, no need to check it at boot."
- "The app shouldn't fail to start over an optional feature's config."
- "If the value is bad, the error when we use it will be clear enough."
- "Adding it to the startup validator means touching another module."

---

## Why It Works

1. **It moves failure to where attribution is free.** A startup crash happens during the deploy, in front of the person who caused it, with the diff still on screen. A first-use crash happens in front of whoever is on call, with no diff in sight.
2. **It makes "is the config valid?" a decidable question.** One pass at boot either succeeds or fails; with call-site validation, the answer requires executing every path, including the ones that run quarterly.
3. **It exploits deploy machinery you already have.** Orchestrators roll back pods that crash at boot automatically; no tooling exists that rolls back a deploy because a cron job died two days later.

## Origin

A team rotated their object-storage configuration and fat-fingered a region name. The web tier never touched that config, so the deploy went green and the week went quietly. Saturday's billing export — the only consumer — crashed, and its retry loop paged on-call every twenty minutes until Monday, when someone finally connected a weekend of failures to a Tuesday deploy. Startup validation would have made it a forty-second rollback. Instead it became a postmortem with this prompt as the remediation.
