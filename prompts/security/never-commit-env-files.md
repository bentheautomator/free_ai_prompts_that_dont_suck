---
title: Never Commit .env Files or Untracked Secrets
slug: never-commit-env-files
category: security
tags: [universal, security, secrets]
works_with: all
severity: critical
one_liner: "AI running git add . and sweeping .env files into the repo"
---

# Never Commit .env Files or Untracked Secrets

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from staging and committing environment files, key files, and other secret-bearing artifacts.

**[Copy-paste ready version](../../install/never-commit-env-files.md)** — just the instruction block, no explanation.

## The Problem

The assistant finishes a feature and runs `git add .` or `git add -A` to stage its work. Sitting in the working tree: `.env` with the database password, `service-account.json` from a cloud console download, maybe an `id_rsa` someone scp'd over for debugging. All of it gets staged, committed, and pushed in one motion, with a commit message about the feature. Nobody notices because the diff is large and the secret files are at the bottom.

This happens because `git add .` is the lowest-effort way to stage changes and the AI is focused on the feature, not the working tree's contents. It happens even in repos with a `.gitignore`, because the AI sometimes creates the `.env` itself earlier in the session (to make the app run) and never adds the ignore entry, or because the secret file has a name the ignore list doesn't cover (`.env.local.backup`, `creds.json`, `dump.sql`).

Once pushed, the secret is in history on every clone and every mirror. `git rm` does not remove it. The only real remediation is rotation plus history rewriting, which is an afternoon of pain that one moment of staging discipline would have prevented.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Commit .env Files or Untracked Secrets

NEVER stage or commit files that contain credentials. Stage files by explicit path; do not use `git add .`, `git add -A`, or `git commit -a` without reviewing exactly what they will pick up.

A committed secret is in history permanently. Removing the file in a later commit does not remove the secret.

- Before any commit, run `git status` and check the untracked list for: `.env` and variants (`.env.local`, `.env.production`), `*.pem`, `*.key`, `id_rsa*`, `*.p12`, `service-account*.json`, `credentials*`, `*.sqlite`/`*.db`/`*.sql` dumps, and editor-created backup copies of any of these.
- If you create a `.env` file during a session, add it to `.gitignore` in the same step, and create a committed `.env.example` with placeholder values instead.
- If a secret-bearing file is already tracked, do not quietly `git rm` it. Tell the user: the credential needs rotation and possibly history rewriting (`git filter-repo`), because every clone already has it.
- Never bypass a gitignore with `git add -f` to "make the build work." Fix the build to read configuration properly instead.
- Pre-commit hooks or secret scanners failing is a stop signal, not an obstacle. Do not amend, skip hooks (`--no-verify`), or rename files to get past them.

**Red flags that you're about to violate this:**
- "git add . is faster and I changed a lot of files..."
- "The .env only has local dev values in it..."
- "I'll commit it now and gitignore it in a follow-up..."
- "The pre-commit hook is blocking the commit, I'll use --no-verify just this once..."
- "It's a private repo, committed secrets aren't a real exposure..."
- "The user told me to commit everything..."

---

## Why It Works

1. **It targets the staging command, not the abstract sin.** The failure happens at `git add .`. Forcing explicit-path staging inserts a review step exactly where the mistake occurs.

2. **It lists the filenames.** AIs are good at matching concrete patterns. `service-account*.json` and `.env.local` catch real files that a generic "don't commit secrets" never would.

3. **It pairs .env creation with .gitignore in one atomic step.** The most common root cause is the AI creating the env file itself and forgetting the ignore entry. Binding the two actions removes the gap.

4. **It defines correct remediation.** Without the rotation rule, the AI's instinct is to delete the file and call it fixed, leaving a live credential in history.

## Origin

An assistant set up a new microservice, created a `.env` with real staging credentials to verify the database connection, then staged the entire directory and pushed. The `.gitignore` it scaffolded covered `node_modules` but not `.env`. The repo was internal, so the team deprioritized cleanup; eight months later the repo was open-sourced with full history, credentials included. Rotation happened the hard way, during an incident.
