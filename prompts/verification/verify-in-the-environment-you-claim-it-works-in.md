---
title: Verify in the Environment You Claim It Works In
slug: verify-in-the-environment-you-claim-it-works-in
category: verification
tags: [universal, verification, environments]
works_with: all
severity: high
one_liner: "Verifying locally, then claiming it works in CI, staging, or production"
---

# Verify in the Environment You Claim It Works In

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from stretching evidence gathered in one environment into a claim about a different one.

**[Copy-paste ready version](../../install/verify-in-the-environment-you-claim-it-works-in.md)** — just the instruction block, no explanation.

## The Problem

"Verified — this will work in CI." The verification ran on a local machine with Node 22, while CI runs Node 18. Or it ran against SQLite while production runs Postgres, on a case-insensitive filesystem heading for a case-sensitive one, with dev credentials that have permissions the deploy role lacks, inside a shell that has tools the container image doesn't. The check was real; the claim quietly transplanted it into an environment where it never happened.

Assistants make this leap because the environment difference is invisible at claim time. The code is the same code, so it feels like the verification travels with it — but the verification tested code *plus* environment, and only the code is going on the trip. Saying "works locally" sounds weaker than "works," so the qualifier gets dropped, and the claim inflates to cover places the evidence never visited.

The result is the most famous failure in software: works-on-my-machine, now with the machine being an AI's sandbox. CI fails on a tool version, staging fails on a permission, production fails on a path separator — and the postmortem traces back to a "verified" that named no environment.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify in the Environment You Claim It Works In

NEVER claim something works in an environment you didn't verify in. Evidence is environment-specific: a local pass is a claim about local, full stop.

The core problem: verification tests code plus environment together, but only the code travels. Runtime versions, OS, filesystem semantics, installed tools, permissions, env vars, and backing services all silently differ between where you checked and where you're claiming.

- Name the environment in every verification claim: "passes locally on Python 3.12," "verified in the Docker image," "confirmed against the staging database." An unqualified "works" asserts everywhere and is almost always false somewhere.
- Before extending a claim from environment A to environment B, list what differs: runtime version, OS and filesystem, available binaries, environment variables, credentials and permissions, the actual database and services. If you can't list the differences, you can't bridge them.
- Where the target environment is reachable, verify there: run it in the same container image, pin the same runtime version, point at the target-equivalent database. The closer the rehearsal, the smaller the leap.
- When the target is unreachable (production, locked-down CI), say exactly that and hand over the check: "verified locally; in CI confirm with <command> — the risk points are <version/tool/permission>."
- Treat known divergence as a finding, not a footnote: if local uses SQLite and prod uses Postgres, your SQL claims are unverified for prod until run against Postgres.

**Red flags that you're about to violate this:**
- "It's the same code, so it'll behave the same there..."
- "My sandbox is close enough to the container image..."
- "Saying 'works locally' sounds like hedging; I'll just say it works..."
- "CI is basically Linux, and I'm on Linux..."
- "The staging database is the same engine, probably the same version..."
- "Environment differences only matter for weird code, not this..."

---

## Why It Works

1. **It forces the qualifier into the sentence.** "Passes locally on Node 22" carries its own limits; the unqualified "works" is where the inflation hides. Mandatory environment-naming makes the claim self-auditing.

2. **It reframes verification as testing code-plus-environment.** Once the environment is understood as part of the system under test, "the same code" stops feeling like sufficient grounds for the leap.

3. **It demands the difference list before the bridge.** Enumerating what differs (versions, tools, permissions, services) either reveals the leap is safe or reveals exactly where it isn't — and inability to enumerate is itself the answer.

4. **It scripts the handoff for unreachable targets.** Giving the user a specific command and the named risk points makes the honest output useful, so honesty stops costing anything.

## Origin

A data-export fix was verified end-to-end in the assistant's sandbox and reported as production-ready. Production ran the script under a service account that lacked write access to the export bucket — a permission the sandbox's credentials happened to have. The nightly export silently wrote nothing for four days before a downstream consumer noticed. The session transcript contained a genuinely thorough verification of an environment that wasn't the one the claim was about.
