---
title: Keep Local Config Overrides Out of Commits
slug: keep-local-config-overrides-out-of-commits
category: configuration
tags: [universal, config, git-hygiene]
works_with: all
severity: high
one_liner: "Stops your localhost overrides riding along in an unrelated commit"
---

# Keep Local Config Overrides Out of Commits

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from sweeping local debugging overrides — localhost URLs, verbose logging, disabled checks — into commits alongside the actual change.

**[Copy-paste ready version](../../install/keep-local-config-overrides-out-of-commits.md)** — just the instruction block, no explanation.

## The Problem

To get the feature working locally, the AI made a few "temporary" config edits: pointed the API client at `http://localhost:4000`, set `log_level: debug`, bumped a timeout to 300 so it could step through the debugger, set `verify_ssl: false` to get past the local proxy. The feature works. Time to commit — and the AI runs `git add -A`, or commits "all the changes I made," which by its own accounting includes the overrides. They were part of making it work, weren't they?

This is the default failure of any agent that equates "files I modified" with "the change." Local overrides are working-state, not work-product, but nothing in the diff marks them as such — `timeout: 300` and the actual feature code look equally intentional. Reviewers skim config hunks hardest of all, so the overrides merge, and now staging logs at debug volume, or an internal client trusts any certificate, or — the classic — some service in production tries to reach `localhost:4000` and the error makes no sense to anyone because nobody remembers the override existed.

The overrides that are *dangerous* are precisely the ones that don't crash: relaxed verification, inflated limits, disabled rate limiting. Those just quietly hold the door open.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Local Config Overrides Out of Commits

NEVER commit config changes you made to get things working locally. Before committing, review every config-file hunk in the diff and revert anything that was working-state rather than part of the requested change.

"Files I modified" and "the change" are different sets. Local overrides belong to the first and must not reach the second.

- Make local overrides in gitignored files when they exist (`.env.local`, `docker-compose.override.yml`, `config/local.*`). If you must edit a tracked file to debug, mark the line with a `# LOCAL — DO NOT COMMIT` comment the moment you make the edit, and grep for that marker before committing.
- At commit time, read the actual diff of every config file (`git diff` on `*.yml`, `*.json`, `.env*`, `*.toml`, settings modules) and justify each hunk against the task. "It was needed to run locally" is a reason to revert it, not include it.
- Treat these as guilty until proven innocent: `localhost`/`127.0.0.1` URLs, `debug` log levels, disabled TLS/auth/rate-limit flags, huge timeouts, `skip`/`mock`/`fake` toggles.
- Never use `git add -A` / `git add .` for commits that touch config files; add files explicitly.
- If an override revealed that the committed default is genuinely wrong, that's a separate, deliberate change with its own explanation — not a stowaway hunk.

**Red flags that you're about to violate this:**
- "I'll just commit everything I changed; it all contributed to the fix."
- "The reviewer will catch it if the timeout shouldn't change."
- "I need this committed or it won't work" (on my machine).
- "Debug logging on is harmless to ship."
- "I'll remember to revert it before pushing."

---

## Why It Works

1. **It splits working-state from work-product as categories,** which is the distinction the AI's "commit my changes" heuristic lacks. Once the categories exist, classifying a `localhost` URL is easy.
2. **The DO-NOT-COMMIT marker turns memory into grep.** "I'll remember to revert it" fails across sessions; a searchable marker survives them.
3. **The guilty-until-proven-innocent list targets the overrides that don't crash** — relaxed security and inflated limits ship silently precisely because nothing downstream complains.
4. **Banning `git add -A` near config removes the mechanism** by which most stowaway hunks actually board the commit.

## Origin

A developer's assistant disabled webhook signature verification in a tracked config file to test against locally-generated payloads, then included the file in the feature commit. The hunk sat mid-diff between two legitimate config additions and was approved. For five weeks the staging environment — which mirrored that config to production during a routine sync — accepted unsigned webhooks. It was found not by review or monitoring but by a curious engineer wondering why their malformed test webhook hadn't been rejected.
