---
title: Keep Environment Conditionals Out of Business Logic
slug: keep-environment-conditionals-out-of-business-logic
category: configuration
tags: [universal, config, environments]
works_with: all
severity: medium
one_liner: "Stops if env == production checks metastasizing through application code"
---

# Keep Environment Conditionals Out of Business Logic

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from scattering `if env == "production"` branches through application code instead of expressing the difference as a config value.

**[Copy-paste ready version](../../install/keep-environment-conditionals-out-of-business-logic.md)** — just the instruction block, no explanation.

## The Problem

The emails shouldn't actually send in development, so the AI writes `if (env !== "production") return;` inside the mailer. Sensible. Then the same move happens in the payment capture path, the webhook dispatcher, the analytics tracker, and the cleanup job — each one a small, locally-reasonable `if`, each one written by an AI (or a person) solving exactly one problem. A year in, the codebase has dozens of environment branches, and "what does staging actually do?" has no answer short of grepping for every spelling of every environment name and simulating the results in your head.

Scattered environment conditionals create two structural problems. First, every new environment breaks them all at once: add a `preview` or `qa` environment and every `env == "production"` / `env == "development"` pair silently mis-sorts it — emails from preview environments going to real customers is the canonical result. Second, the code becomes untestable-as-prod: you can't exercise production behavior in a test without lying about the environment globally, which flips every *other* scattered conditional too.

The fix is mechanical: business logic asks "is email sending enabled?" — a capability — and only config decides which environments enable which capabilities, in one file you can read.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Environment Conditionals Out of Business Logic

NEVER branch on the environment name (`if env == "production"`) inside application code. Express the difference as a named config value — a capability — and let per-environment config set it. Business logic asks `config.email_sending_enabled`, never `env == "prod"`.

Scattered env-name checks turn "what does staging do?" into a grep-and-simulate exercise, and every new environment mis-sorts through all of them simultaneously.

- When you're about to write an environment check in app code, name the behavior it controls instead: `send_real_emails`, `payments_live_mode`, `strict_cors`. Add that key to the config layer, set it appropriately per environment, and branch on the key.
- The environment name should be consumed in approximately one place: the config loader that selects which value-set to apply. If `APP_ENV` is read anywhere else, that's the smell.
- Don't enumerate environments in logic (`env in ["staging", "production"]`) — the list is stale the day someone adds an environment, and it fails silently for the new one.
- When working in code that already has env conditionals, don't add siblings. Match the task's scope: introduce the capability key for your change, and flag the neighbors for conversion.
- Capabilities also make the safety default explicit: a new environment with no config gets the key's declared default (choose the safe one), instead of whatever side of a string comparison it happens to land on.

**Red flags that you're about to violate this:**
- "It's just one if-statement, a config key is ceremony."
- "This behavior is inherently about production, checking the name is honest."
- "There are already env checks in this file, I'm being consistent."
- "We only have three environments, the enumeration is fine."
- "I'll check `env != 'development'` so it's safe everywhere else."

---

## Why It Works

1. **Capabilities centralize the environment-behavior map into config you can read,** replacing N scattered conditionals (auditable only by grep) with N lines in a file (auditable by looking).
2. **New environments inherit declared defaults instead of falling through string comparisons.** The `preview`-environment-sends-real-email bug is impossible when the key defaults to off and each environment opts in explicitly.
3. **It restores testability:** you can enable one production behavior in a test by setting one key, without impersonating production globally and dragging every other conditional along.
4. **The one-consumer rule for `APP_ENV` gives reviewers a trivially checkable invariant** — any new read of the env name outside the config loader is a violation on its face.

## Origin

A team added a `demo` environment for sales, cloned from staging. Eleven scattered conditionals checked `env == "development"` to suppress side effects; `demo` matched none of them, so it behaved as production in every one. The demo environment spent an afternoon sending real provisioning webhooks to a partner's live endpoint while a sales engineer clicked through fake customers. The cleanup involved an apology call; the remediation collapsed all eleven checks into four capability keys and one config file where `demo`'s row was, finally, something a human could review.
