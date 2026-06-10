---
title: Verify APIs Against the Installed Version
slug: verify-api-against-installed-version
category: code-quality
tags: [universal, apis, dependencies]
works_with: all
severity: high
one_liner: "AI using APIs from a library version the project doesn't actually have"
---

# Verify APIs Against the Installed Version

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from writing code against a different version of a library than the one the project has installed.

**[Copy-paste ready version](../../install/verify-api-against-installed-version.md)** — just the instruction block, no explanation.

## The Problem

The method exists. It's in the docs. It's just not in *your* version. An AI assistant writes `app.useRouter()` from React Router v6 into a project pinned to v5, or calls `Model.objects.abulk_create()` in a Django 3.2 codebase where async ORM methods don't exist yet. The code is real — for somebody else's dependency tree.

This is sneakier than a pure hallucination because every verification instinct confirms the API is legitimate. The docs describe it. Stack Overflow has examples. The model has seen it ten thousand times in training. The only thing wrong is the number in your lockfile, which the AI never looked at. Models default to the API surface they saw most recently or most often in training, which usually means the latest major version — while real projects routinely sit one or two majors behind.

The failure shows up as an import error if you're lucky, or as an `AttributeError` deep in a request handler if you're not. Either way, someone burns twenty minutes confirming that yes, the method is real, before realizing the question was never "does it exist" but "does it exist *here*."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify APIs Against the Installed Version

NEVER write code against a library API without confirming the project's installed version supports it. "The docs say it exists" is not verification — the docs describe a version; the lockfile describes reality.

You default to the newest API surface you know, but real projects pin older versions. An API that arrived in v6 is a runtime error in a v5 project, and it will pass every "is this method real" check because it is real — elsewhere.

**Before using a library API:**
- Check the pinned version in `package.json`, the lockfile, `requirements.txt`, `pyproject.toml`, `go.mod`, `Gemfile.lock`, or equivalent
- Confirm the specific method, option, or signature exists in that version — check the installed package source or the changelog, not just current docs
- If the codebase already uses the library, copy the call patterns it uses; they're version-correct by definition
- Pay special attention across major version boundaries — that's where APIs get added, renamed, and removed
- If a feature genuinely requires a newer version, say so explicitly and let the user decide whether to upgrade; do not silently write code that assumes the upgrade happened

**Red flags that you're about to violate this:**
- "The current documentation shows this method, so it's safe..."
- "This has been the standard API for a while now..."
- "I'll use the modern syntax for this library..."
- "Most projects are on the latest version anyway..."
- "The migration to the new API is straightforward, they've probably done it..."
- Writing a library call without having looked at a single version number in this session

---

## Why It Works

1. **It splits "real" from "available."** The AI's verification instinct stops at "this API exists." The instruction redefines the question as "this API exists *in the pinned version*," which the AI can only answer by reading the manifest — forcing the check at the exact point where confidence is misleading.

2. **It redirects to version-correct evidence.** Existing calls in the codebase can't be from the wrong version. Pointing the AI at them replaces training-data recall with ground truth.

3. **It names the major-version boundary.** Most version drift failures cluster at major bumps. Flagging that specifically concentrates scrutiny where the breakage actually lives.

4. **It provides an honest escape hatch.** "Say the feature needs a newer version" removes the temptation to quietly write aspirational code, because there's an approved way to handle the mismatch.

## Origin

A team asked their assistant to add request retries to a service using a popular HTTP client. The AI used the client's built-in retry transport — a feature added two major versions after the one pinned in the project. CI didn't catch it because the test suite mocked the client entirely. The service crashed on boot in staging, and the "fix" spiraled into an unplanned dependency upgrade with its own breaking changes, turning a one-hour task into a two-day yak shave.
