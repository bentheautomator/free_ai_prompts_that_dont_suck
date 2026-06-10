---
title: Check the License Before Adding a Package
slug: check-the-license-before-adding-a-package
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: high
one_liner: "Stops pulling GPL or no-license code into proprietary projects unexamined"
---

# Check the License Before Adding a Package

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding a dependency whose license is incompatible with how the project ships.

**[Copy-paste ready version](../../install/check-the-license-before-adding-a-package.md)** — just the instruction block, no explanation.

## The Problem

License is the one dependency attribute AI assistants reliably never check. An assistant evaluating a package will sometimes glance at popularity or API shape, but the license field — the part that determines whether your company is legally allowed to ship the thing — doesn't appear in any error message, doesn't break any build, and so never enters the loop. The assistant picks the package that best solves the problem, and the problem as framed never includes "and we distribute a closed-source product."

Most of the ecosystem is MIT/Apache/BSD and genuinely fine. But the exceptions are landmines: GPL and AGPL packages impose copyleft obligations that can extend to your code, with AGPL reaching even network-served software; "fair source" and BUSL licenses restrict commercial use in ways that read like open source until paragraph four; and some packages have no license at all, which legally means all rights reserved — you may not have permission to use it in any product. None of this is visible at install time. It surfaces later, during an acquisition's due diligence or a customer's compliance audit, when removing the dependency means rewriting whatever grew around it.

The check is nearly free: `npm view <pkg> license` is one command, and the registry page states it for every ecosystem. Assistants skip it because nothing in the feedback loop ever punished skipping it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check the License Before Adding a Package

ALWAYS check a package's license before adding it as a dependency, and state the license in your summary of the change. License compatibility is a shipping requirement, not a legal nicety — the wrong license in the tree can mean the product cannot legally be distributed as-is.

- Check with one command: `npm view <pkg> license`, `pip show <pkg>` after install, `cargo add` output, or the registry page. Do this for every new dependency, every time.
- Permissive licenses (MIT, Apache-2.0, BSD, ISC) are generally safe to adopt without escalation. Note them and move on.
- Stop and ask the user before adding anything copyleft (GPL, AGPL, SSPL) to a project that isn't itself open source under a compatible license. AGPL applies even when the software is only served over a network, not distributed.
- Treat "no license," "UNLICENSED," custom licenses, and source-available licenses (BUSL, fair-source variants) as blockers requiring explicit human sign-off. No license means no permission.
- LGPL and MPL sit in between — usually workable with conditions (dynamic linking, file-level copyleft) that depend on how the project uses the code. Name the condition when you flag it.
- This applies to code you vendor or copy as much as packages you install. Pasting a function from a GPL repository carries the license with it.

**Red flags that you're about to violate this:**
- "It's on npm, so it's open source and fine to use."
- "License review is a lawyer problem, not an engineering step."
- "Everyone uses this package; the license must be permissive."
- "It's just a dev dependency, the license doesn't matter." (often true, worth confirming, never assuming)
- "I'll add it now; someone can audit licenses later."

---

## Why It Works

1. **It adds license to the AI's selection loop**, where nothing else ever puts it — there is no error message, test failure, or warning that fires on a license problem, so only an explicit rule can.
2. **It tiers the response** — proceed, flag, or block — so the AI doesn't escalate every MIT install to the user, which would get the whole rule ignored within a week.
3. **It corrects the specific misconception that public means permissive**, including the genuinely surprising cases: no-license-is-all-rights-reserved, and AGPL's network clause.
4. **It requires the license in the change summary**, making the check auditable rather than claimable.

## Origin

An assistant added a PDF-generation library to a commercial SaaS backend — the best library for the job, and AGPL-licensed, which it never mentioned. The dependency sat in the tree for over a year until a prospective enterprise customer's procurement scan flagged it. By then, PDF generation was woven through the billing system, and replacing the library under a deal deadline took three engineers two weeks. The permissively licensed alternative they migrated to had been the second search result all along.
