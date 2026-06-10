---
title: Deprecate Config Keys Before Deleting Them
slug: deprecate-config-keys-before-deleting-them
category: configuration
tags: [universal, config, lifecycle]
works_with: all
severity: critical
one_liner: "Stops deleting config keys that other services and scripts still read"
---

# Deprecate Config Keys Before Deleting Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from removing a config key the moment this repo stops using it, while other services, scripts, and humans still depend on it being set.

**[Copy-paste ready version](../../install/deprecate-config-keys-before-deleting-them.md)** — just the instruction block, no explanation.

## The Problem

The refactor removed the last in-repo read of `LEGACY_API_HOST`, so the AI — being tidy, which is normally a virtue — deletes the key everywhere: env template, compose file, the shared `app-config` ConfigMap, the values file that several services consume. Grep says zero usages. Grep is scoped to one repo. The sidecar in another repo reads that ConfigMap key. The on-call runbook says `echo $LEGACY_API_HOST` to find the failover target. A cron job in the infra repo sources the same env file. None of them appear in this repo's grep, and all of them just lost a value they read.

Config keys are a publication, not a private variable. Once a key exists in a shared store — a ConfigMap, a shared env file, a values file, a config service — you no longer control its consumer list, and "no usages in this repo" stops being evidence of "no usages." AI assistants delete on local evidence because local evidence is all they have, and because key removal looks like the responsible cleanup half of any refactor.

Unlike code deletion, which fails at build time, config deletion fails at *other people's* runtime: the consumer gets an empty value or a missing key, often falls back to a default, and misbehaves quietly in someone else's service where the cause is your diff.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Deprecate Config Keys Before Deleting Them

NEVER delete a config key from a shared location just because this repo no longer reads it. A key in a shared store (ConfigMap, shared env file, values file, config service) has consumers you cannot grep for: other repos, sidecars, cron jobs, scripts, runbooks, humans.

Code deletion fails your build. Config deletion fails someone else's runtime.

- Distinguish scope before deleting. A key in this repo's own config, read only by this repo's code: deletable with the code. A key in anything shared or deployed where other processes can read it: deprecation process, not deletion.
- Deprecation process: mark the key deprecated (comment with date and replacement), announce it in the change description with a removal date, keep its value flowing in the meantime, and remove it in a later, dedicated change after the window passes.
- "No usages found" must state its search scope. If you searched one repo, say "no usages in this repo" — and treat that as insufficient for shared keys. Search sibling repos, infra repos, and runbooks if you can; name the ones you couldn't.
- Removing the value while keeping the key (setting it empty) is deletion with worse error messages. Don't.
- Stopping the *production* of a value others consume (the job that writes a config entry, the export that populates it) is the same failure mode as deleting the key. Same process.
- If the key holds something dangerous-to-keep (a decommissioned endpoint that now points somewhere wrong), say so explicitly and make the removal a coordinated change, not a cleanup commit.

**Red flags that you're about to violate this:**
- "Grep shows nothing reads this anymore."
- "I removed the code that used it, so removing the key is part of the same cleanup."
- "If something else needed it, that would be documented somewhere."
- "Leaving unused keys around is clutter; better to delete now."
- "Worst case, whoever needs it can re-add it."

---

## Why It Works

1. **It severs the false symmetry with code cleanup.** The AI bundles key deletion into refactors because dead code and dead config look alike; stating that config consumers are unenumerable breaks the analogy at its load-bearing joint.
2. **Scope-stamped evidence ("no usages in this repo") prevents single-repo grep from masquerading as global proof** — the exact inference that causes these incidents.
3. **A deprecation window converts unknown consumers into self-identifying ones.** People who read the announcement object before the removal; people who didn't get a window in which their breakage is diagnosable, because the key is marked, not vanished.
4. **Covering value-production stops the equivalent failure that key-focused rules miss:** the key survives, but nothing fills it.

## Origin

A platform team's repo dropped its last reference to a `region_failover_map` entry in a shared config store and deleted the entry in the same PR, title: "remove dead config." Grep was clean — in that repo. A traffic-routing service in another repo read the entry hourly and, finding it absent, fell back to its default of "no failover configured." This was discovered three weeks later, during an actual regional incident, when failover quietly didn't happen. The routing service's logs showed the config went missing twenty days before anyone needed it — the worst possible way to learn who your consumers are.
