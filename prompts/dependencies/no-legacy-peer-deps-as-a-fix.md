---
title: No --legacy-peer-deps as a Fix
slug: no-legacy-peer-deps-as-a-fix
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: high
one_liner: "Stops silencing peer dependency conflicts with force flags unresolved"
---

# No --legacy-peer-deps as a Fix

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from using `--legacy-peer-deps` or `--force` to make a peer dependency conflict disappear without understanding it.

**[Copy-paste ready version](../../install/no-legacy-peer-deps-as-a-fix.md)** — just the instruction block, no explanation.

## The Problem

`ERESOLVE unable to resolve dependency tree` is one of the most common npm errors, and the most common advice for it — repeated in thousands of GitHub issues the model trained on — is `npm install --legacy-peer-deps`. So that's what AI assistants do. The error vanishes, the install completes, and nobody mentions that the flag's entire function is to ignore the incompatibility, not resolve it.

A peer dependency conflict is a package saying, in machine-readable form, "I was not built for the version of React/ESLint/webpack you have." Forcing the install past that declaration means running a combination the author explicitly ruled out. Sometimes it works. Sometimes it fails at runtime with hook errors, duplicate-instance bugs, or plugin crashes that appear nowhere near the install. And once `--legacy-peer-deps` lands in an npm script or `.npmrc`, every future conflict in the project is silenced too — the project has permanently opted out of compatibility checking.

The assistant reaches for the flag because it pattern-matches error to remedy without reading what the conflict actually says. The ERESOLVE output names both packages and both version requirements; the answer is usually right there.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No --legacy-peer-deps as a Fix

NEVER use `--legacy-peer-deps`, `--force`, or equivalent conflict-suppression flags as the response to a peer dependency error. These flags do not resolve the conflict; they install a combination of packages that one of the authors has explicitly declared incompatible.

- Read the ERESOLVE output. It names the package, the peer it requires, and the version you have. Resolve the actual mismatch: pick a version of the new package that supports your existing peer, or upgrade the peer deliberately as its own reviewed change.
- Check whether a compatible version exists before concluding there's a real conflict: `npm view <pkg> peerDependencies` per version, or read the package's compatibility table.
- If no compatible version exists, report that honestly: "this package does not yet support React 19; the options are wait, use an alternative, or knowingly force it." Forcing is the user's call to make, not yours.
- Never add `--legacy-peer-deps` to `.npmrc`, CI config, or package.json scripts. That converts a one-time judgment call into permanent project-wide suppression of all future conflicts.
- If an override is genuinely the right tool (a package's peer range is stale but it works), use a targeted `overrides`/`resolutions` entry for that one package, with a comment, instead of a global flag.

**Red flags that you're about to violate this:**
- "ERESOLVE errors are usually fixed with --legacy-peer-deps."
- "The peer ranges are probably just outdated; forcing it will be fine."
- "I'll add the flag to .npmrc so the install works everywhere."
- "This is a known npm quirk, not a real incompatibility."
- "Getting the install green is the priority; compatibility can be checked later."

---

## Why It Works

1. **It translates the flag into what it actually does** — "install a combination the author ruled out" — replacing the AI's learned framing of it as a standard fix.
2. **It redirects attention to the error text.** ERESOLVE output contains the resolution path; the rule makes reading it the required first step instead of an optional one.
3. **It distinguishes the one-time escape hatch from permanent suppression.** Blocking the flag in `.npmrc` and scripts prevents the most damaging variant, where the project silently stops checking compatibility forever.
4. **It assigns the forcing decision to the human**, with the tradeoff stated, which is where a knowingly-unsupported configuration belongs.

## Origin

An assistant adding a charting library hit a peer conflict with the project's React version and installed with `--legacy-peer-deps`, then committed the flag into the project's `.npmrc` "so CI would pass." Months later a second, unrelated incompatibility — a form library that genuinely did not work with the installed React — sailed through install with no warning and crashed at runtime in production. The team only discovered the `.npmrc` line while writing the postmortem.
