---
title: Don't Vendor Packages by Copy-Paste
slug: dont-vendor-packages-by-copy-paste
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: medium
one_liner: "Stops copying library source into the repo instead of declaring the dependency"
---

# Don't Vendor Packages by Copy-Paste

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from pasting a library's source into the repo as an ad-hoc, untracked, license-stripped fork.

**[Copy-paste ready version](../../install/dont-vendor-packages-by-copy-paste.md)** — just the instruction block, no explanation.

## The Problem

Sometimes installing a package is inconvenient — the environment is offline, the package manager errored, or only one function from the library is needed — and the assistant takes a shortcut: it copies the library's source code into the repo. A `utils/retry.js` appears containing four hundred lines that are recognizably a popular retry library with the comments shaved off. No attribution, no version recorded, no entry in any manifest.

This creates the worst kind of dependency: one that no tool knows exists. Security scanners audit your manifest, not your `utils/` directory, so when the original library patches a vulnerability, the copy stays vulnerable forever and nothing will ever tell you. Upstream bug fixes never arrive. The license — which almost certainly requires the copyright notice the paste removed — is now being violated. And future maintainers treat the code as homegrown, "fixing" it in ways that drift from upstream until reconciliation is impossible.

Assistants do this because pasting code is their most fluent operation and it sidesteps whatever made the install awkward. The model has the library's source memorized, near enough, so reproducing it feels equivalent to depending on it. It isn't: a declared dependency has a version, an upgrade path, an audit trail, and a license attached. A paste has none of those.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Vendor Packages by Copy-Paste

NEVER copy a library's source code into the repository as a substitute for declaring it as a dependency. A pasted library is an invisible fork: no version, no security scanning, no upstream fixes, and usually a license violation.

- If the project needs a library, declare it in the manifest and install it. If the install fails, fix the install problem — don't route around the package manager by pasting its output.
- Needing one small function from a big library is not a paste license. Either take the dependency, or write your own genuinely original implementation of the small thing. Reproducing the library's implementation from memory is still copying, including its license obligations.
- If vendoring is truly required (offline builds, policy reasons, patched fork), do it properly and visibly: a dedicated `vendor/` directory, the exact upstream version and source URL recorded, the LICENSE file included, and a note on how to update. Vendoring is a documented decision, not a paste.
- Never strip or omit license headers and copyright notices from copied code. For most open-source licenses, keeping the notice is the main condition of being allowed to copy at all.
- If you find pasted-library code in the repo while working, flag it — it's an unpatched, unscannable dependency someone doesn't know they have.

**Red flags that you're about to violate this:**
- "The install is failing, but I can just inline the library's code."
- "We only need one function, so copying it in is leaner than a dependency."
- "I'll reproduce it from memory, so it's not really copying."
- "It's open source; that means I can paste it anywhere."
- "Putting it in utils/ keeps the dependency count down."

---

## Why It Works

1. **It names what a paste actually is — an invisible fork** — replacing the AI's frame of "leaner than a dependency" with the true cost: no scanning, no fixes, no version.
2. **It closes the from-memory loophole.** The AI genuinely believes reproducing code it memorized is original work; stating that it's still copying, license and all, removes that rationalization.
3. **It legitimizes real vendoring** with a checklist (version, URL, LICENSE, update notes), so projects with valid offline or fork needs have a compliant path instead of a forbidden one.
4. **It keeps the security argument concrete**: scanners read manifests, so a pasted library is precisely the dependency that never gets patched.

## Origin

A repo's `helpers/` directory turned out to contain a hand-pasted copy of a well-known sanitization library, added by an assistant eighteen months earlier when an install had failed behind a corporate proxy. The original library had since shipped two security patches for bypass bugs; the pasted copy had neither, and no scanner ever flagged it because no manifest ever mentioned it. The bug report that finally exposed it came from a penetration test, the expensive way to run `npm audit`.
