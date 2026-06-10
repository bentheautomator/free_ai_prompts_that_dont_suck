---
title: Prove the Config Value Is in Effect
slug: prove-the-config-value-is-in-effect
category: verification
tags: [universal, verification, configuration]
works_with: all
severity: high
one_liner: "Treating an edited config file as proof the running system uses that value"
---

# Prove the Config Value Is in Effect

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from claiming a configuration change is active when the system is still resolving a different value.

**[Copy-paste ready version](../../install/prove-the-config-value-is-in-effect.md)** — just the instruction block, no explanation.

## The Problem

Configuration has layers, and the file you edited is only one of them. Environment variables override files, CLI flags override environment variables, a `.local` file shadows the base file, a profile section beats the default section, and a typo'd key name is silently ignored while the built-in default carries on. An assistant edits one layer, sees the new value in that file, and announces "the timeout is now 60 seconds" — a claim about the system, supported only by evidence about one file.

This happens because the effective value is invisible from the editor. Checking it requires asking the running system — a debug endpoint, a `--show-config` flag, a log line at startup, a query against the live settings object — and assistants skip that step because the edited file looks like the answer. The claim is about resolution order, but the verification only covered authorship.

The resulting bugs are uniquely slippery: the config file says one thing, the system does another, and everyone trusts the file. Teams have "tuned" values for days with zero effect because an environment variable set in the deploy manifest was winning the whole time.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Prove the Config Value Is in Effect

NEVER claim a configuration value is active based on the file you edited. Claim it only after the running system has told you the value it is actually using.

The core problem: config resolves through layers — defaults, files, local overrides, environment variables, flags — and editing one layer proves nothing about which layer wins. The effective value is a property of the running system, not of any file.

- After changing config, get the effective value from the system itself: a startup log line that prints settings, a debug/health endpoint, a `--show-config` or `print-config` command, a REPL read of the live settings object, or observable behavior that only the new value could produce.
- Check for shadowing before trusting any file edit: environment variables, `.env` and `.local` variants, profile- or environment-specific sections, deploy manifests, and CLI flags can all override what you wrote.
- Verify the key name, not just the value. A misspelled key throws no error in most systems; it is simply ignored and the default applies. Silence is not acceptance.
- Confirm the system reread its config after your change (restart or documented reload) — and then still check the effective value, because reload and resolution are separate failure points.
- If you cannot query the effective value, scope the claim: "the file now sets X to Y; confirm the running value with <command>."

**Red flags that you're about to violate this:**
- "The value is right there in the file, that's what it'll use..."
- "This is the main config; nothing else would override it..."
- "No error on startup, so the new setting was accepted..."
- "I'll assume standard precedence rather than checking it..."
- "The key name looks right — close enough to the docs..."

---

## Why It Works

1. **It relocates the claim's subject.** "The timeout is 60 seconds" sounds like a statement about a file but is actually a statement about a running process. Naming that mismatch makes file-only evidence visibly insufficient.

2. **It inventories the override layers.** Env vars, local files, profiles, flags — each is a specific place the truth can hide. A concrete list converts "did anything override it?" from a shrug into a check.

3. **It flags the silent-typo failure.** Most config systems ignore unknown keys without complaint, so "no error" is genuinely zero evidence. Stating that closes the most comfortable loophole.

4. **It accepts only system-sourced evidence.** Log line, endpoint, live object — every approved proof comes from the resolver itself, which is the only component that knows who won.

## Origin

A team asked an assistant to raise a worker's queue batch size. It edited `settings.yaml`, confirmed the new number was in the file, and reported the change live after a restart. Throughput didn't move for two days of escalating mystery. The deploy chart set `BATCH_SIZE` as an environment variable — which the settings loader preferred over the file — so the system had been running the old value the entire time. One startup log line printing the effective config would have ended the mystery before it began.
