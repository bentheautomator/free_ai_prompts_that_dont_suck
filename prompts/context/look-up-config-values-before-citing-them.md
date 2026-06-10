---
title: Look Up Config Values Before Citing Them
slug: look-up-config-values-before-citing-them
category: context
tags: [universal, config, verification]
works_with: all
severity: high
one_liner: "AI stating 'your timeout is 30 seconds' for a value it never looked up"
---

# Look Up Config Values Before Citing Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from quoting specific configuration values it never read from any file.

**[Copy-paste ready version](../../install/look-up-config-values-before-citing-them.md)** — just the instruction block, no explanation.

## The Problem

"Your connection pool is capped at 10, which is why requests queue under load." A specific number, a causal explanation, a satisfied user — and the AI never opened the config. The 10 is the library's default, or a number from training data, or pure invention. The pool in this project is set to 50, the queueing has a different cause entirely, and the debugging session just turned down a dead-end street with great confidence.

Cited config values are load-bearing in a way prose isn't. Numbers anchor debugging ("the timeout is 30s, so the failure at 25s isn't a timeout"), capacity planning ("the heap is 2GB, so..."), and security posture ("CORS is locked to your domain"). A fabricated value doesn't just misinform — it eliminates hypotheses. The user crosses off the real cause because the AI's confident number ruled it out.

What makes this failure so frequent is that defaults are genuinely knowable. The AI often does know the library's default timeout. But "the default is 30s" and "your timeout is 30s" are different claims, and the second requires evidence the first doesn't: someone has to check whether this project overrode it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Look Up Config Values Before Citing Them

NEVER state a specific configuration value for this project — a timeout, a port, a pool size, a limit, a flag — without having read it from an actual source this session. "The default is X" and "your value is X" are different claims; the second requires evidence.

A fabricated config value doesn't just misinform — it falsely eliminates hypotheses during debugging, because numbers read as measurements.

**Before citing any config value:**
- Read it from where it actually lives: config files, `.env` files, environment-specific overlays, constants files, CLI flags in scripts, infrastructure manifests (Dockerfile, compose, k8s, terraform)
- Resolve the full chain: a value can be set in the config file, overridden by an env var, and overridden again by a flag — cite the value that wins, and say where it's set
- When the project doesn't set a value, say exactly that: "this isn't configured here, so it falls back to the library default, which is X in version Y" — labeling the default as a default
- During debugging, quote the line you found (`config/database.yml: pool: 50`) so the user can verify and so the source is on record
- If a value differs per environment, say which environment you read — the dev timeout is not evidence about prod

**Red flags that you're about to violate this:**
- "Your timeout is set to 30 seconds, so..."
- "The pool size here is 10, the standard setting..."
- "This is configured to retry three times..."
- "Your CORS policy only allows your own domain..."
- "I remember this value from earlier" — without re-checking after edits
- Typing a specific number about this project's behavior that appears in no file you've read this session

---

## Why It Works

1. **It splits the two claims.** "The default is X" vs "your value is X" is the exact boundary the AI blurs. Once separated, the second claim visibly demands a file-read the first doesn't, and the blur becomes detectable.

2. **It names the hypothesis-elimination hazard.** Wrong numbers don't just add noise — they subtract truth from debugging sessions. That framing raises the stakes from "minor inaccuracy" to "sabotaged investigation."

3. **It requires resolving the override chain.** Config file, env var, flag — citing the losing layer is as wrong as inventing. Demanding the winning value with its source closes the partial-lookup loophole.

4. **It mandates quoting the line.** A citation the user can check is also a citation the AI can't fake — you cannot quote `pool: 50` from a file you never opened.

## Origin

During an incident, an AI assured the team their job queue's visibility timeout was 300 seconds — "the standard configuration" — so the duplicate-processing bug had to be elsewhere. The team spent four hours auditing worker idempotency. The actual config file set the timeout to 30 seconds, jobs routinely outran it, and the queue was redelivering in-flight work exactly as configured. The number the AI invented had ruled out the true cause in the incident's first ten minutes.
