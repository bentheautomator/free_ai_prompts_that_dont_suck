---
title: Never Overwrite Local Env Files
slug: never-overwrite-local-env-files
category: code-safety
tags: [universal, files, config]
works_with: all
severity: high
one_liner: "AI clobbering a developer's .env with example values during setup"
---

# Never Overwrite Local Env Files

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from replacing a developer's accumulated local configuration with template defaults.

**[Copy-paste ready version](../../install/never-overwrite-local-env-files.md)** — just the instruction block, no explanation.

## The Problem

Setup instructions say `cp .env.example .env`, so the AI runs `cp .env.example .env` — onto a machine where `.env` already exists and has existed for eight months. It held a dozen working API keys, OAuth client credentials someone in another department provisioned once and may not remember how to re-provision, tuned local ports, feature flags, and a database URL with a non-obvious password. All of it is now `your-api-key-here`. Because `.env` files are gitignored, there's no history, no diff, no recovery. The file's whole value was that it had been *filled in*, and filling it in again means a scavenger hunt across dashboards, password managers, and coworkers' memories.

The AI hits this from several directions: following README setup steps literally on an already-set-up machine, "fixing" an env issue by regenerating the file from the example, adding one new variable by rewriting the whole file from the template, or scaffolding a feature whose setup script blindly copies templates over. In each case it treats the env file as derived from the example — when actually the example is derived from it, minus everything that matters.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Overwrite Local Env Files

NEVER overwrite an existing `.env` or local config file with a template, example, or regenerated version. These files are gitignored, which means no history and no recovery — and their value is precisely the accumulated real values (keys, credentials, tuned settings) that the template lacks.

The core problem: setup steps like `cp .env.example .env` are written for fresh machines. On a machine that's already set up, the same command destroys months of accumulated working configuration.

- Before any write to `.env*`, `config.local.*`, `settings.local.*`, `*.local.yml`, or similar local-config paths: check whether the file exists. If it exists, you are editing, never replacing.
- To add a variable, append it or do a targeted edit. Never regenerate the file from the example "with the new variable included."
- If a setup procedure says to copy a template, gate it: `[ -f .env ] || cp .env.example .env` — and use that guarded form in any setup script you write.
- If the user explicitly wants the file reset, copy the existing one aside first (`cp .env .env.bak-$(date +%Y%m%d)`) and say where the backup is. Real keys are painful to re-obtain.
- Diff-merge if the template gained new variables: add the missing keys to the existing file rather than the existing values to a fresh template — you'll miss fewer things.
- Extend the same respect to other filled-in local files: IDE workspace settings, local override YAMLs, `docker-compose.override.yml`.

**Red flags that you're about to violate this:**
- "Step one of the README is to copy the example env..."
- "Their env file seems off — I'll regenerate it from the template..."
- "Easiest way to add the new variable is to rewrite .env from .env.example..."
- "It's just config, the values can be filled in again..."
- "I'll reset the env to known-good defaults..."

---

## Why It Works

1. **It reverses the derivation arrow.** The AI models `.env` as generated-from-example; stating that the example is the *stripped* version makes overwriting it register as deleting the only filled-in copy, not refreshing a derived file.

2. **It names the no-recovery property.** "Gitignored = no history" preempts the implicit "git will have it" safety assumption that makes the AI casual about config files in repos.

3. **It hardens the setup-script path.** The guarded copy (`[ -f .env ] ||`) fixes not just the AI's own behavior but the scripts it writes, which is where this failure reproduces itself.

## Origin

Onboarding a project onto a new feature, an assistant followed the README verbatim — including the `cp .env.example .env` step — on the lead developer's primary machine. The destroyed file had held credentials for nine services, two of which required support tickets to reissue. Setup took four days to fully reassemble, which is impressive for a command that ran in under a millisecond.
