---
title: Suspect the Data and Config, Not Just Code
slug: suspect-the-data-and-config-not-just-code
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: high
one_liner: "AI hunting code defects when the bug is a config value or a bad row"
---

# Suspect the Data and Config, Not Just Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from searching source code for a defect that lives in an environment variable, a config file, or a database row.

**[Copy-paste ready version](../../install/suspect-the-data-and-config-not-just-code.md)** — just the instruction block, no explanation.

## The Problem

Code is what an AI assistant can read, search, and edit — so code is where it looks, no matter where the bug actually lives. But a huge fraction of production failures involve no code defect at all: an environment variable typo'd in one environment, a feature flag set differently than everyone assumes, a database row corrupted by an old migration, a certificate that expired, a config file with staging credentials in production, an upstream feed that changed its date format last Tuesday. In every one of these, the source can be read forever and the bug will never appear in it — because the source is *correct*, and the world it runs against is not.

The signature of this failure is an assistant proposing increasingly improbable code theories for behavior the code plainly doesn't produce: "perhaps under certain conditions this branch..." No. The branch does what it says. The *input* to the branch — the config it loaded, the row it fetched, the response it received — is not what anyone believes it is, and nobody has actually looked at it.

The fix-side version is just as bad: when the bug *is* bad data, patching code to tolerate it (special-casing the corrupt row in application logic) instead of repairing the data and fixing whatever produced it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Suspect the Data and Config, Not Just Code

NEVER limit a bug hunt to source code. The program's behavior is a function of code *and* configuration *and* data *and* environment — and the last three are invisible in the repo, which is exactly why bugs hide there.

If the code you're reading plainly doesn't produce the observed behavior, stop re-reading it and start inspecting what it was given.

- Early in any investigation, enumerate the non-code suspects: environment variables actually loaded, config files and their override order, feature flags per environment, secrets and certificates (expiry!), the specific database rows involved, external API responses as received, file permissions, disk space, system clock
- Inspect actual values, not intended ones: print the loaded config at runtime, query the real rows, capture the real upstream response — the deploy docs say what *should* be set, the process knows what *is*
- Environment-specific failures (works in dev, fails in prod; works for everyone but one customer) are config/data bugs until proven otherwise — diff the environments and the accounts, don't re-read shared code that behaves differently in only one place
- When the bug is bad data: repair it, *and* find what produced it (a buggy migration, a race, an old code version) — and check for siblings, because corruption rarely hits exactly one row
- Never special-case known-bad data in application code as the fix; that hardcodes the corruption into the program permanently
- Code theories that require "perhaps under certain conditions" contortions are a signal to switch suspects: the simple explanation is that the inputs aren't what you think

**Red flags that you're about to violate this:**
- "Let me re-read this function again; the bug must be in here somewhere..."
- "Maybe under some rare condition this correct-looking code does the wrong thing..."
- "It only fails in production, so let me study the shared business logic..."
- "I'll add a special case for this one record..."
- Five files read, zero actual runtime values inspected
- Never having asked what config the failing process actually loaded

---

## Why It Works

1. **It widens the suspect pool explicitly.** The AI's search space defaults to what it can grep; enumerating config, data, environment, and time as co-equal suspects corrects a blind spot that is structural, not motivational.

2. **It uses theory-contortion as the switch signal.** "Perhaps under certain conditions" is the audible sound of forcing a code explanation onto a non-code bug; flagging it gives the AI a precise moment to change strategy.

3. **It separates intended from actual values.** Most config bugs survive because everyone checks the documentation instead of the process; "print what actually loaded" closes the gap where the bug lives.

4. **It handles the data-bug endgame.** Repair plus producer-hunt plus sibling-check is the complete treatment; banning the special-case patch prevents the corruption from becoming a permanent resident of the codebase.

## Origin

Payments failed in production only, and an assistant spent a day in the payment service's code — proposing three theories about retry logic and idempotency keys, each refuted. The production config, when someone finally printed what the process had actually loaded, contained the sandbox API endpoint: a deploy script had been writing the wrong value for one region since a refactor two weeks earlier. No code in the repo could have revealed it, and the assistant had read most of the repo trying.
