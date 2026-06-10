---
title: Only Import Installed Packages
slug: only-import-installed-packages
category: code-quality
tags: [universal, dependencies]
works_with: all
severity: critical
one_liner: "AI importing packages that aren't installed, or don't exist at all"
---

# Only Import Installed Packages

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from importing packages that aren't in the project's dependencies — or that don't exist anywhere.

**[Copy-paste ready version](../../install/only-import-installed-packages.md)** — just the instruction block, no explanation.

## The Problem

The AI writes `import dateparser` into a project whose `requirements.txt` has never heard of it. Mild version: the package is real but uninstalled, and now your "small code change" silently grew a dependency decision nobody made — new supply-chain surface, new license to vet, new thing to keep patched, smuggled in as a side effect. Worse version: the package doesn't exist at all. The model hallucinated a plausible name (`python-jsonfix`, `react-use-debounce-hook`) the way it hallucinates plausible methods.

The hallucinated-package case has graduated from annoyance to attack vector. The names models invent are *consistent* — different sessions hallucinate the same fake packages — and people have taken to registering those names on public registries with malicious payloads, a technique known as slopsquatting. An AI that writes the import, plus a user who reflexively runs `pip install` on whatever the error message names, equals arbitrary code execution on a dev machine with your SSH keys on it. That promotion in stakes is why this rule is not just about build hygiene.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Only Import Installed Packages

NEVER import a package that isn't in this project's declared dependencies. Check the manifest — `package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile` — before writing any third-party import.

This rule has teeth for two reasons. First, an uninstalled-but-real package is an unauthorized dependency decision: supply-chain surface, licensing, and maintenance burden added as a side effect of a code edit. Second, a package you *invented* is now a security incident waiting to happen — attackers register the plausible-sounding names AI models consistently hallucinate (slopsquatting), so "just install the missing package" can mean installing malware.

**Rules:**
- Before any third-party import: confirm the exact package name appears in the dependency manifest. Exact — `psycopg2` vs `psycopg2-binary`, `discord.py` vs `discord`, scoped vs unscoped npm names all differ
- If the functionality needs a package that isn't installed: STOP and say so. Name the package, why it's needed, and let the user decide to add it. Never write the import and let the error prompt an install
- Never instruct the user to `pip install` / `npm install` a package you haven't verified exists on the official registry under that exact name
- Prefer solving with what's already installed or the standard library before proposing any new dependency
- Transitive availability doesn't count: a package being pulled in by another dependency is not a license to import it directly

**Red flags that you're about to violate this:**
- "This is a very common package, it's surely installed..."
- "There's a package for this — I believe it's called..."
- "They can just install it if it's missing..."
- "I've seen this import in countless projects..."
- "The dependency of their dependency includes it, so importing is fine..."
- Writing a third-party import without the manifest open in this session

---

## Why It Works

1. **It reclassifies the act.** The AI frames an import as a code detail; the instruction reframes it as a dependency decision with security and licensing consequences — a category the model treats with appropriate caution.

2. **It names slopsquatting explicitly.** Knowing that hallucinated names are *predictably* hallucinated, and therefore squattable, converts "worst case is an import error" into "worst case is malware" — which changes the verification calculus entirely.

3. **It cuts the install-reflex loop.** The dangerous pattern is import error → paste name into installer. Requiring a stop-and-ask at the missing-package moment breaks the loop at its only interruptible point.

4. **It demands exact-name matching.** Near-miss names (`psycopg2-binary`, scoped packages) are where "I checked" quietly fails. Specifying exactness closes the gap between checking and confirming.

## Origin

An assistant generated a data pipeline that imported a YAML-helpers package which did not exist — yet. The developer pasted the `ModuleNotFoundError` name into pip, got a successful install, and moved on; the name had been registered on the public index three months earlier with a post-install script that exfiltrated environment variables. The compromise was caught by egress monitoring the same week, but rotating every credential that had ever lived in that shell took the team most of a sprint.
