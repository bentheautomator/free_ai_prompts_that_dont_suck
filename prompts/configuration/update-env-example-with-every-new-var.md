---
title: Update .env.example With Every New Var
slug: update-env-example-with-every-new-var
category: configuration
tags: [universal, config, env-vars]
works_with: all
severity: high
one_liner: "Stops new env vars landing in code while .env.example stays stale"
---

# Update .env.example With Every New Var

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from introducing a new environment variable in code without declaring it in `.env.example` (or the project's equivalent template).

**[Copy-paste ready version](../../install/update-env-example-with-every-new-var.md)** — just the instruction block, no explanation.

## The Problem

The AI wires up a new integration, adds `process.env.WEBHOOK_SIGNING_KEY` to the code, sets the value in its own local `.env` to test it, and ships. The code works on that machine. `.env.example` — the file every other developer and every deploy pipeline treats as the contract for "what this app needs" — never hears about it. The next person who clones the repo gets a runtime crash (best case) or a feature that silently doesn't work (worst case), and they get to discover the missing var by reading source code.

This happens because `.env` is gitignored, so from the AI's point of view the work is done: code changed, value set, tests pass. The example file is invisible to the task. There's no compiler error, no failing test, nothing in the diff that says "you forgot the contract file." Reviewers don't catch it either, because the absence of a line in `.env.example` doesn't show up in a diff.

The cost compounds. Each undeclared var widens the gap between "what the example says you need" and "what the app actually needs," until onboarding becomes archaeology: grep the codebase for `env`, ask in Slack, copy someone's `.env` over coffee. The example file exists precisely to prevent that, and it only works if it's updated in the same commit as the code that creates the need.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Update .env.example With Every New Var

ALWAYS update `.env.example` (or the project's env template: `.env.sample`, `.env.dist`, `env.template`, config README) in the same change that introduces a new environment variable. A new env var read in code is an interface change; the example file is the interface declaration.

- When you add any read of a new env var (`process.env.X`, `os.environ["X"]`, `ENV["X"]`, `os.Getenv("X")`), add the same key to the example file in the same commit.
- Use a placeholder or safe example value, never a real one: `STRIPE_WEBHOOK_SECRET=whsec_xxx`, not a live secret. Add a one-line comment saying what it's for and whether it's required or optional.
- Keep ordering and grouping consistent with the existing file. Put the new var next to related ones, not at the bottom.
- If the project has multiple template files (e.g., `.env.example` and `docker-compose.yml` environment blocks, or a Helm values file), update every place that enumerates env vars. Search for an existing var name to find them all.
- If the project has no env template at all, say so and ask whether to create one — don't silently leave the new var undocumented.
- Removing or renaming a var follows the same rule: the example file changes in the same commit.

**Red flags that you're about to violate this:**
- "I set it in .env locally, so the app runs fine."
- "It's optional, so it doesn't really need to be in the example."
- ".env is gitignored, so env vars aren't part of the diff."
- "I'll add it to the docs later once the feature settles."
- "Whoever deploys this will know they need to set it."

---

## Why It Works

1. **It reframes a new env var as an interface change, not a local detail.** The AI treats env reads like internal variables; calling the example file "the interface declaration" puts it in the same mental category as a function signature, which the AI already knows must stay in sync.
2. **It names the invisibility problem.** The AI's working state (its own `.env`) makes the app run, which reads as "done." Stating that `.env` is gitignored and therefore proves nothing forces the check against the committed contract instead.
3. **It closes the "optional var" loophole** — the most common rationalization — by requiring optional vars to be declared with a comment rather than omitted.
4. **It extends the rule to every enumeration point** (compose files, charts, docs), so the fix doesn't just move the drift one file over.

## Origin

A feature branch added rate limiting backed by a new `REDIS_RATE_LIMIT_URL` variable, tested against the author's local Redis. `.env.example` wasn't touched. Staging had the var set by hand during testing; production didn't, and the limiter's connection failed at boot two weeks later when the feature flag flipped on. The on-call engineer spent ninety minutes diffing staging and production environments before grepping the code and finding a variable that, per every document in the repo, did not exist.
