---
title: Verify Versions Are Extinct Before Removing Checks
slug: verify-versions-extinct-before-removing-checks
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Stops removal of version guards for versions still alive in the field"
---

# Verify Versions Are Extinct Before Removing Checks

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting version checks for runtimes, schemas, and environments it assumes died out, when the fleet says otherwise.

**[Copy-paste ready version](../../install/verify-versions-extinct-before-removing-checks.md)** — just the instruction block, no explanation.

## The Problem

`if (engineVersion < 5.6)`, `if sys.version_info < (3, 9)`, `if schema_version == 2` — version guards read like history lessons, and AI assistants grade them by the calendar. Python 3.8 is end-of-life; that database version is six majors behind; surely the guard is dead weight. The assistant removes it, and the code now assumes a floor that the real fleet doesn't meet.

The calendar is the wrong instrument. End-of-life dates describe vendor support, not field reality. Real environments are a museum: the on-prem customer running the database version from their last maintenance window in 2021, the CI runner image nobody rebuilt, the air-gapped deployment that upgrades annually, the one region still on the old cluster, the self-hosted installs you have no telemetry for. Version guards exist because the code runs in many places, and the assistant can see exactly one of them — usually the dev environment, usually the newest.

What makes this failure expensive is where it lands: the environments running old versions are by definition the slow-moving ones — enterprise, regulated, air-gapped — and the breakage often surfaces only at their next upgrade or deploy, far from the change that caused it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Versions Are Extinct Before Removing Checks

NEVER remove a version check because the version it guards is old, end-of-life, or "surely gone." A guard is removable only when the version is verified extinct across every environment the code ships to — and the environments most likely to run old versions are the ones you can't see.

Before removing any version guard (runtime, OS, database, schema, protocol, dependency):

- Identify the deployment surface honestly. Is this code SaaS-only, or does it ship to self-hosted installs, on-prem customers, multiple regions, or CI images? Every distribution channel is a place old versions survive.
- Look for a declared support floor: setup/requirements metadata, engine constraints, compatibility matrices in docs, support policy pages. Removing a guard below the declared floor is a breaking change to a published promise.
- Ask what the fleet actually runs if telemetry or an inventory exists. "EOL upstream" and "absent from our fleet" are different facts; only the second justifies removal.
- Check why the guard was added: `git blame` it. A guard added for a specific customer or environment needs that specific situation confirmed dead.
- When the floor genuinely rises, raise it properly: update the declared minimum in the same change that removes the guards, so the assumption becomes explicit and testable instead of silently embedded.
- When you can't verify, leave the guard and say why: "Removal assumes no environment runs below X; I can't confirm that."

**Red flags that you're about to violate this:**
- "That version has been end-of-life for years."
- "No one could still be running this in production."
- "Our dev and staging environments are way past this version."
- "This guard never triggers in any recent logs I can see."
- "The vendor doesn't even support that version anymore."
- "If someone's that far behind, this is the least of their problems."

---

## Why It Works

1. **It splits "EOL" from "extinct."** The AI's reasoning runs on vendor timelines; the instruction forces it onto fleet data, which is the only timeline that determines breakage.
2. **It maps the habitats of old versions** — self-hosted, air-gapped, regulated, stale CI images — so "surely gone" gets tested against the specific places versions actually hide.
3. **The declared-floor check converts the question into contract terms.** If the project promises compatibility down to version X, guard removal below X is identifiably a breaking change, not cleanup.
4. **"Raise the floor explicitly" gives the right action a shape.** Version guards should eventually die — via a deliberate, documented minimum bump, not via silent assumption smuggled into a refactor.

## Origin

A self-hosted analytics product carried a guard around a database feature unavailable before a certain engine version, with a fallback query for older installs. An assistant modernizing the data layer dropped the fallback; the engine version it guarded was years past end-of-life and absent from every environment the team operated. Two months later, three of the largest self-hosted customers — running the engine their security team had certified in 2020 — upgraded the product and got startup crashes. Their version wasn't in anyone's telemetry because self-hosted installs reported nothing. The compatibility matrix in the docs had promised them support the whole time.
