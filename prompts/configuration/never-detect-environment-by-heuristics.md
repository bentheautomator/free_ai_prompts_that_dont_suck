---
title: Never Detect Environment by Heuristics
slug: never-detect-environment-by-heuristics
category: configuration
tags: [universal, config, environments]
works_with: all
severity: critical
one_liner: "Stops guessing prod vs dev from hostnames, paths, or other vibes"
---

# Never Detect Environment by Heuristics

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from inferring which environment it's running in from hostnames, file paths, usernames, or URL patterns instead of an explicit declaration.

**[Copy-paste ready version](../../install/never-detect-environment-by-heuristics.md)** — just the instruction block, no explanation.

## The Problem

The AI needs the code to behave differently in production, and there's no obvious environment variable in sight. So it improvises: `if socket.gethostname().startswith("prod-")`, or `if "staging" in request.url`, or `if os.path.exists("/home/deploy")`. It works on every machine the AI can reason about, which is to say, the ones that happen to match the pattern today.

Heuristic environment detection fails in exactly one direction that matters: a machine that *is* production but doesn't look like it. The new region where hostnames follow a different convention. The container whose hostname is a random hash. The disaster-recovery replica spun up under a different naming scheme during the one incident where you can least afford config confusion. When the heuristic misfires, the application doesn't crash — it confidently runs with the wrong environment's behavior: debug endpoints exposed in prod, prod safeguards active in a load test, or, in the truly catastrophic case, "I'm not prod, so it's safe to wipe this database."

AI assistants invent these heuristics because they're locally clever. The detection logic needs no new env var, no deploy coordination, no asking anyone — it just reads what's already there. That's also why it's a trap: what's already there was never promised to mean anything.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Detect Environment by Heuristics

NEVER infer the runtime environment from hostnames, file paths, usernames, URL substrings, IP ranges, or the presence of files. The environment must be explicitly declared (e.g., `APP_ENV`), and code must read only that declaration.

Heuristics encode "what production happens to look like today." Infrastructure changes — new regions, container hostnames, DR replicas — and the heuristic silently classifies a production machine as not-production, with production consequences.

- Read the environment from one explicit, documented source: an env var like `APP_ENV` / `ENVIRONMENT`, or the platform's official mechanism. If the project already has one, use it; never add a second.
- If no explicit declaration exists where you need one, stop and say so. Do not bridge the gap with `hostname`, `NODE_ENV`-sniffing-adjacent tricks, checking for `/.dockerenv`, or "if the DB host contains 'prod'".
- If the environment is undeclared at runtime, fail or assume the most-restrictive environment — never assume "not production," because the most dangerous machine to misclassify is a prod box that looks unusual.
- Destructive operations gated on environment (dropping schemas, seeding data, deleting buckets) must check the explicit declaration AND require their own confirmation; a guessed environment is not a safety check.
- The same rule applies to detecting "am I in CI" or "am I in a container": use the documented variable (`CI=true`), not directory archaeology.

**Red flags that you're about to violate this:**
- "Prod hostnames all start with 'prod-', so I can just check that."
- "There's no APP_ENV set, but I can tell from the database URL."
- "If the .git directory exists, we're obviously on a dev machine."
- "This heuristic covers every environment we currently have."
- "It's just for deciding log verbosity, it doesn't need to be exact."

---

## Why It Works

1. **It points at the failure direction that matters.** The AI evaluates heuristics against environments it can imagine; the rule names the unimaginable one — the prod machine that doesn't look like prod — where misclassification means wrong-environment writes.
2. **Defaulting to most-restrictive inverts the cheap assumption.** Untrained fallback logic assumes "unknown = dev" because dev is common; the rule makes unknown expensive instead of dangerous.
3. **Separating environment checks from safety confirmation** means a wrong guess degrades behavior instead of authorizing destruction.
4. **It closes the "low stakes" loophole** — heuristics introduced for log verbosity get copy-pasted into delete guards within the year.

## Origin

A data team's cleanup script refused to run against production, enforced by checking whether the database hostname contained `prod`. A migration moved the production database behind a connection pooler whose hostname was an opaque identifier. The script's guard concluded it was looking at a test database and truncated fourteen tables of live data during a routine run. The restore took eleven hours; the postmortem's root cause was one line of hostname string-matching that had been "working" for three years.
