---
title: Never Ship Default or Seeded Credentials
slug: no-default-credentials
category: security
tags: [universal, security, secrets]
works_with: all
severity: critical
one_liner: "AI seeding admin/admin users and password fallbacks that reach production"
---

# Never Ship Default or Seeded Credentials

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from creating well-known default logins and fallback passwords that survive into production.

**[Copy-paste ready version](../../install/no-default-credentials.md)** — just the instruction block, no explanation.

## The Problem

Scaffolding an app, an AI wants it to work immediately after `npm run seed`, so it creates `admin@example.com / admin123`, or an `.env.example` with `JWT_SECRET=changeme` that gets copied to `.env` verbatim, or code like `process.env.ADMIN_PASSWORD || "password123"` so startup never fails. Each of these is a credential that the AI chose, that appears in the repository, and that nobody is forced to change. Seed scripts run in production more often than anyone plans ("we just needed the reference data"), `.env.example` values get deployed by people who treat the file as a template to fill in *some* of, and the `||` fallback activates silently whenever the env var has a typo in its name.

Default credentials are among the oldest and most reliably exploited weaknesses there is — botnets are built on them. The AI-specific twist is that AI-generated defaults converge: models trained on the same tutorials produce the same `admin/admin`, the same `secret`, the same `changeme`, making the guessing game even easier. And because the default makes the system work, there is no error, no failing test, no signal at all that production is running on a password the whole internet can guess.

The principle: a system should be incapable of running with a credential the developer didn't explicitly set. Absence of configuration should mean failure, not fallback.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Ship Default or Seeded Credentials

NEVER create credentials that work without someone explicitly choosing them. Missing secret configuration must crash the app at startup, not activate a fallback.

A default password is a published password. AI-generated defaults are extra-guessable because every model produces the same ones.

- Never write fallbacks for secrets: `process.env.JWT_SECRET || "secret"`, `os.environ.get("ADMIN_PASS", "admin123")`, or config defaults for keys, signing secrets, or passwords. Validate at startup and exit with a clear message when they're missing.
- Seed scripts must not create privileged accounts with fixed passwords. For local dev convenience, generate a random password at seed time and print it once, or read it from a required env var; gate any dev-user creation on an explicit environment check that refuses to run in production.
- `.env.example` and documentation must contain non-working placeholders (`JWT_SECRET=<generate with: openssl rand -hex 32>`), never plausible values someone can deploy unchanged. Include the generation command so the right action is the easy one.
- First-run setup for products: require the operator to set the initial admin credential during installation (setup wizard, CLI prompt, or required env var). Never pre-create `admin/admin` "to be changed on first login" — first login is exactly when the attacker arrives.
- Docker compose files and Helm values count: `POSTGRES_PASSWORD: postgres` in a committed compose file becomes a production password with depressing regularity. Use env-file indirection or generated secrets there too.
- When you encounter an existing default credential pattern while working, flag it; if a known-default value might already be live, the user needs to rotate, not just patch the code.

**Red flags that you're about to violate this:**
- "A fallback secret keeps local development friction-free..."
- "The seed admin is just for the demo environment..."
- "Everyone knows to change the values in .env.example..."
- "It crashes on startup without a default, and crashing is bad UX..."
- "First-login password change will force them to fix it..."
- "The compose file is only for local development anyway..."

---

## Why It Works

1. **It inverts the failure direction.** The AI adds defaults so the app always starts; mandating crash-on-missing makes misconfiguration loud instead of silently insecure, which is the entire fix in one design decision.

2. **It names the convergence problem.** "Defaults are published" is abstract; "every model generates admin123" makes the guessability concrete and personal to AI-written code.

3. **It provides the convenient-but-safe seed pattern.** Random-at-seed-time with a printed password preserves the one-command dev setup the AI is protecting, removing the actual motivation for the fixed password.

4. **It includes the generation command in placeholders.** `<generate with: openssl rand -hex 32>` doesn't just block the bad value; it makes the correct action copy-pasteable, which is the currency AIs and humans both trade in.

## Origin

A self-hosted analytics tool's setup script, written with assistant help, created an admin account with a documented default password "to be changed after install." A scan-the-internet crawler logged into hundreds of deployments that never changed it, including one belonging to the tool's own maintainers, and used the admin panel's export feature to pull usage data. The patched installer refuses to complete until the operator sets a password, and the version with the default was yanked.
