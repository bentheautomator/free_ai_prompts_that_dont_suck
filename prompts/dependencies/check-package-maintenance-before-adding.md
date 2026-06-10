---
title: Check Package Maintenance Before Adding
slug: check-package-maintenance-before-adding
category: dependencies
tags: [universal, dependencies, supply-chain]
works_with: all
severity: high
one_liner: "Stops adopting packages last published in 2017 with open security issues"
---

# Check Package Maintenance Before Adding

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding an abandoned package because it remembers the name from training data.

**[Copy-paste ready version](../../install/check-package-maintenance-before-adding.md)** — just the instruction block, no explanation.

## The Problem

An AI assistant's sense of which package to use is frozen at training time, and skewed toward whatever was popular in years of accumulated tutorials. Ask it to add CSV parsing, retry logic, or JWT handling, and it may confidently install a package whose last release was six years ago, whose issue tracker has 200 open items including unpatched vulnerability reports, and whose README opens with "this project is no longer maintained."

An abandoned package isn't just stale — it's a dead end you build on. It will never support the next major of your framework. Its bugs are permanent. When a CVE lands, there is no one to ship the patch, and your options become forking it or migrating off it under deadline pressure. The npm graveyard is full of once-canonical names that assistants still recommend because the tutorials never got rewritten.

The check that prevents this takes seconds and the assistant can run it itself: `npm view <pkg> time.modified` shows the last publish date; the registry page shows whether the maintainer marked it deprecated; the repo shows whether anyone has merged a PR this decade. Assistants skip it because recall feels like knowledge — the package name comes to mind fluently, and fluency gets mistaken for currency.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Package Maintenance Before Adding

ALWAYS verify that a package is actively maintained before adding it as a dependency. Your knowledge of the ecosystem is frozen at training time; the package you remember as standard may have been abandoned years ago.

- Check the last publish date before installing: `npm view <pkg> time.modified`, `pip index versions <pkg>` plus the PyPI page, or the registry website. No release in 2+ years for an actively-evolving problem domain is a stop sign.
- Check for an explicit deprecation: npm prints deprecation notices on install — never ignore them, and never install a package you already know is deprecated.
- Glance at the repository: recent commits, whether issues get responses, whether the README announces abandonment or points to a successor. Many dead packages name their replacement; use it.
- Weigh maintenance against role. An abandoned 50-line leftpad-style utility is low risk; an abandoned HTTP client, auth library, or framework plugin is a future migration with a deadline you don't control.
- When you choose a package, state in one line when it last shipped and why you trust it. If the best-known package is dead and the alternatives are obscure, present that tradeoff to the user instead of silently picking either.

**Red flags that you're about to violate this:**
- "This is the standard library everyone uses for this."
- "I've seen this package in hundreds of examples."
- "The download count is huge, so it must be fine."
- "Checking the publish date is overkill for a quick install."
- "It worked in the tutorial, and the API won't have changed."

---

## Why It Works

1. **It attacks the fluency-equals-currency confusion directly.** The AI's strongest signal — "this name appears everywhere in my training data" — is precisely the signal that goes stale, and the rule says so.
2. **It converts "maintained" into commands** with concrete outputs, so the check is mechanical rather than a judgment the AI can wave through.
3. **It scales the bar by blast radius.** Distinguishing trivial utilities from load-bearing infrastructure prevents both the overcorrection (refusing tiny helpers) and the real failure (adopting a dead HTTP client).
4. **It requires a stated justification**, which makes a skipped check visible in the output instead of silent.

## Origin

Asked to add request retries to a Node service, an assistant installed a once-popular HTTP wrapper whose final release predated the project's Node version by four majors. It worked until the team upgraded Node, at which point a deprecated API the package used internally was removed and every outbound request path broke at once. Migrating to a maintained client took a week — during which the team learned the package's own README had said "unmaintained, please migrate" since before their project existed.
