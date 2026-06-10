---
title: Verify the Package Exists Before Installing
slug: verify-package-exists-before-install
category: dependencies
tags: [universal, dependencies, supply-chain]
works_with: all
severity: critical
one_liner: "Stops installing hallucinated package names that may exist as malware"
---

# Verify the Package Exists Before Installing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents installing a package name the assistant invented — names that attackers register precisely because assistants invent them.

**[Copy-paste ready version](../../install/verify-package-exists-before-install.md)** — just the instruction block, no explanation.

## The Problem

AI assistants hallucinate package names. They blend two real libraries into one plausible-sounding name, guess that a Python package follows the same naming as its npm cousin, or invent the SDK package a vendor "should" have published. Then they run `pip install` or `npm install` on the invention. Sometimes the install fails and you lose five minutes. Sometimes it succeeds — because someone registered that exact name knowing assistants would hallucinate it. This is slopsquatting, and it is an active, documented attack pattern: register the names models commonly invent, ship credential-stealing install scripts, wait.

The failure is structural. Models generate the most plausible token sequence, and plausible-sounding package names are exactly what they produce when the real name is absent from training data or ambiguous. The assistant has no built-in step that distinguishes "package I remember" from "package I just composed," so it installs both with equal confidence.

The blast radius is not a broken build. A malicious package executes code on the developer's machine at install time, before a single import runs.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify the Package Exists Before Installing

NEVER install a package whose existence and identity you have not verified against the registry. A plausible name is not a real name — hallucinated package names get registered by attackers specifically to catch this mistake, and installation alone executes their code.

- Before any `npm install`, `pip install`, `cargo add`, `gem install`, or equivalent: verify the package on the registry first. Use `npm view <name>`, `pip index versions <name>` or the PyPI page, `cargo search <name>`, or fetch the registry URL directly.
- Verify identity, not just existence: does the description match what you expect? Does it have a real repository link, a plausible download count, and a version history older than a few weeks? A name that exists but was first published last month with no repo is a red flag, not a green light.
- Be especially suspicious of names you produced by analogy: "the Python version is probably called X," "the official SDK is probably `@vendor/thing`." Analogy is exactly how hallucinated names are formed.
- If you cannot verify (no network, registry unreachable), say so and present the install command for the user to vet — do not run it.
- Scoped/official packages: confirm the scope is the vendor's actual scope, not a lookalike.

**Red flags that you're about to violate this:**
- "The package is probably just called that."
- "It follows the usual naming convention, so this should be it."
- "The install will fail anyway if it doesn't exist."
- "I remember this package from somewhere."
- "It's the official SDK, the name is obvious."

---

## Why It Works

1. **Kills the safety myth:** "the install will fail if it's wrong" is the rationalization that makes this feel low-risk; the instruction names it and explains why a successful install is the dangerous outcome.
2. **Forces a check before the irreversible step:** install scripts run at install time, so verification has to happen before the command — the instruction pins the check to that exact moment.
3. **Targets analogy-formed names:** the most dangerous hallucinations come from naming-convention reasoning, and the instruction flags that reasoning pattern specifically.
4. **Defines "verified":** existence, matching description, repo link, age, and downloads — preventing the loophole where "it exists" passes as verification.

## Origin

An assistant was asked to add error monitoring to a Flask service and confidently installed a package whose name combined the vendor's brand with "-sdk" — a name the vendor never used. The name resolved on PyPI: a two-week-old package with no repository and a `setup.py` that exfiltrated environment variables. It ran in CI with deploy credentials in scope before anyone looked at the diff. The cleanup involved rotating every secret the pipeline had ever seen.
