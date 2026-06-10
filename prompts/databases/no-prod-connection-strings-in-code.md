---
title: No Prod Connection Strings in Code or Configs
slug: no-prod-connection-strings-in-code
category: databases
tags: [universal, databases, sql]
works_with: all
severity: high
one_liner: "Hardcoding prod database URLs into scripts, configs, and fallbacks"
---

# No Prod Connection Strings in Code or Configs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents production database URLs from being hardcoded into scripts, test configs, and "helpful" fallback defaults.

**[Copy-paste ready version](../../install/no-prod-connection-strings-in-code.md)** — just the instruction block, no explanation.

## The Problem

The AI needs a script to connect, and there's a working connection string right there, in the conversation, in `.env`, in the deploy config. So it does the expedient thing: pastes it into the script. `conn = psycopg2.connect("postgresql://app:s3cret@prod-db.internal:5432/app")`. Or the politer version: `os.environ.get('DATABASE_URL', 'postgresql://...prod...')`, a fallback default that means "when configuration is missing, quietly use production." That script gets committed, copied, and re-run for months. Every future execution, by anyone, in any context, CI, a new hire's laptop, a cron box, talks to prod, whether or not anyone meant it to.

This is two failures braided together. One is credential exposure: a password in source code is in git history forever, visible to everyone with repo access, and unrotatable without breaking the hardcoded copy. The other is target confusion downstream: hardcoded URLs and prod-pointing fallbacks are precisely how later sessions, human and AI, end up running cleanup scripts against production "by default." The hardcoder creates the wrong-database incident that someone else's session completes.

The AI does it because a literal string is the shortest path to "the script works," and because the conversation handed it a real connection string, which it treats as material to use rather than a secret to handle.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Prod Connection Strings in Code or Configs

NEVER hardcode a database connection string, especially a production one, into source code, scripts, test configs, or notebook cells. And NEVER use a real database URL as a fallback default.

A hardcoded URL is a credential leaked into git history plus a landmine: every future run of that file targets that database, regardless of who runs it or why.

- Read connection info from the environment or a config system, and fail loudly when it's absent:
  `url = os.environ['DATABASE_URL']  # KeyError if unset, which is correct`
  Not: `os.environ.get('DATABASE_URL', '<real url>')`. The right fallback for a missing database URL is an error, never a database.
- If the user pastes a connection string into the conversation, use it for the immediate session if asked, but do not write it into any file. If they ask you to hardcode it, propose the env-var version and note the git-history problem once.
- Test configs must not contain shared or remote database URLs; tests get a local/ephemeral database, configured by environment.
- One-off scripts take the connection as an explicit required argument (`--database-url`), making every run name its target.
- Example/template configs (`.env.example`) get obviously fake values: `postgresql://user:pass@localhost:5432/app_dev`, never a real host.
- If you find an existing hardcoded prod URL while working, flag it: it's a leaked credential needing rotation, not just style debt.

**Red flags that you're about to violate this:**

- "The connection string is right here, easiest to inline it..."
- "It's an internal hostname, not really a secret..."
- "A fallback default makes the script work out of the box..."
- "This script is temporary, it won't be committed..."
- "I'll use the prod URL in the test config just to get the suite running..."

---

## Why It Works

1. **It targets the fallback pattern by name.** `get('DATABASE_URL', <prod>)` looks defensive, which is why AIs write it; stating that a missing URL should error, not default, inverts the politeness that creates the trap.

2. **It treats pasted credentials as handling, not material.** The conversation itself is the leak vector; distinguishing "use for this session" from "write into files" lets the AI be useful without propagating the secret.

3. **It frames the future-run problem.** "Works now" is the AI's success criterion; pointing out that the file outlives the session and re-targets prod on every future run extends the evaluation horizon to where the damage lives.

4. **It makes discovery a duty.** Flagging found hardcoded URLs converts the rule from "don't add new ones" into gradual cleanup of the existing minefield.

## Origin

A data-export script written months earlier had the production read-replica URL as its env-var fallback. The replica was later promoted during a failover, making the URL a writable primary. A batch job re-using the script's connection helper then ran "cleanup" deletes against what everyone believed was a scratch database. The deletes were recoverable; the password, which had been in git history across three repos the helper was copied into, had to be rotated everywhere at once on a Friday night.
