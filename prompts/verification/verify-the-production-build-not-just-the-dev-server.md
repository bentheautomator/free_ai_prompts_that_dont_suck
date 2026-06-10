---
title: Verify the Production Build Not Just the Dev Server
slug: verify-the-production-build-not-just-the-dev-server
category: verification
tags: [universal, verification, builds]
works_with: all
severity: high
one_liner: "Verifying in dev mode and claiming the shipped production artifact works"
---

# Verify the Production Build Not Just the Dev Server

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from verifying the dev-mode version of an app and claiming the production artifact works.

**[Copy-paste ready version](../../install/verify-the-production-build-not-just-the-dev-server.md)** — just the instruction block, no explanation.

## The Problem

Dev mode and production are two different programs that happen to share source code. The dev server runs unminified code with hot reload, permissive env handling, debug-mode framework behavior, and lazy on-demand compilation; the production artifact is minified, tree-shaken, ahead-of-time compiled, env-stripped, and assembled by a build pipeline with opinions. An assistant verifies everything against `npm run dev` — thoroughly, honestly — and reports the app ready to ship. What ships is the *other* program, the one nobody ran.

The gap eats real changes: tree-shaking drops the "unused" module that was actually loaded dynamically; minification breaks code relying on function names; an environment variable available in dev is absent from the production env allowlist; debug-mode-only framework behavior papers over a bug that strict production mode exposes; the production build itself simply fails on something the incremental dev compiler tolerated. None of this is visible from dev mode, which is why verifying there feels complete.

Assistants default to dev mode because it's the running thing — already up, instantly reloading, friction-free. Producing and serving the production build is a slower loop with no new features to show for it. So the cheap program gets the verification and the expensive program gets the claim.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify the Production Build Not Just the Dev Server

NEVER claim work is ready to ship, deployable, or production-ready when your verification ran only in dev mode. The dev server and the production build are different programs; evidence about one is not evidence about the other.

The core problem: production builds minify, tree-shake, precompile, strip env vars, and disable debug behavior. Each of those transforms can break code that runs perfectly under the dev server — and none of them run in dev mode.

- Before any ship-ready claim, run the production build command itself and confirm it succeeds. The dev compiler's tolerance is not the build pipeline's tolerance; build failure is a routine first finding.
- Then run or serve the built artifact (the framework's preview/serve-dist mode, the compiled binary, the release configuration) and exercise your changed paths against it at least once.
- Give targeted suspicion to the transform-sensitive changes: dynamic imports and anything tree-shaking might drop, code reading function/class names (minification renames them), environment variables (production allowlists and inlining differ), debug-vs-strict framework behavior, dev-only proxies and CORS handling.
- Dev-mode verification remains worth doing and worth reporting — as itself: "verified against the dev server; production build not yet run" is an honest status. "Ready to ship" is not available from that evidence.
- When you can't produce the production build (missing secrets, build farm only), name the gap and the highest-risk transforms for this change: "works in dev; the dynamic import in X is the thing to watch in the prod build."

**Red flags that you're about to violate this:**
- "It works on the dev server, so it's done..."
- "The production build is just an optimized version of the same code..."
- "Building for production takes minutes; the dev check covers it..."
- "Env vars are env vars — if dev sees them, prod will..."
- "Minification doesn't change behavior, by definition..."
- "I'll let the deploy pipeline be the first to run the build..."

---

## Why It Works

1. **It declares the two programs distinct.** "Different programs sharing source" replaces the mental model ("prod is dev, but faster") under which dev evidence seems to transfer — once they're distinct artifacts, the transfer obviously needs its own check.

2. **It makes the build itself the first checkpoint.** Plenty of failures are caught by merely running the production build; requiring that one command catches the cheapest, most common gap before any deeper verification is needed.

3. **It lists the transform-sensitive change types.** Dynamic imports, name-dependent code, env handling, debug-mode behavior — a concrete watchlist turns "could anything differ?" into a scan with known targets.

4. **It prices the honest status correctly.** "Verified in dev; prod build pending" keeps dev verification valuable while making clear which claims it cannot fund.

## Origin

A frontend feature passed every check against the dev server and shipped with "fully working" in the summary. The feature loaded a locale module via a dynamically constructed import path; the production bundler, unable to statically resolve it, excluded the locale files from the build. In dev — where modules are served on demand — it had worked flawlessly. In production, every non-default-locale user got a blank settings page. The fix was one bundler hint; finding it required only doing what the claim said had been done: running the thing that shipped.
