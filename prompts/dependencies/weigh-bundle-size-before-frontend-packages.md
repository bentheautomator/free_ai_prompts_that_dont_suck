---
title: Weigh Bundle Size Before Frontend Packages
slug: weigh-bundle-size-before-frontend-packages
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: medium
one_liner: "Stops shipping 300 KB of dependency to the browser for one small feature"
---

# Weigh Bundle Size Before Frontend Packages

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding heavyweight packages to browser bundles without considering what every user now downloads.

**[Copy-paste ready version](../../install/weigh-bundle-size-before-frontend-packages.md)** — just the instruction block, no explanation.

## The Problem

On the server, a chunky dependency costs disk space nobody counts. In the browser, every byte of it travels to every user on every cold load — and AI assistants pick frontend packages as if that distinction didn't exist. Need to show a relative timestamp? Here's `moment` with its locales, a famously large addition for what one `Intl.RelativeTimeFormat` call does natively. Need a chart? Here comes a full charting suite for a single sparkline. Need deep cloning? `lodash`, imported in the style that defeats tree-shaking.

The cost lands on the people least able to complain: users on mid-range phones and slow connections, who get a longer white screen so the dashboard could format a date. It accrues invisibly — no test fails when the bundle grows, builds succeed at any size, and each individual addition is defensible. Ten assistant-added conveniences later, the app ships megabytes of JavaScript and nobody can name the decision that did it, because it wasn't one decision.

Assistants behave this way because package selection in training data is dominated by capability and popularity, with weight rarely mentioned. The information is public — bundlephobia.com, `npm view <pkg> dist.unpackedSize`, the package's own docs on tree-shaking — but nothing in the task loop asks for it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Weigh Bundle Size Before Frontend Packages

ALWAYS consider download weight before adding a dependency to code that ships to the browser. A frontend dependency is paid for by every user on every cold load; "it's just one package" is a per-visitor tax.

- Check the cost before installing: bundlephobia.com or `npm view <pkg> dist.unpackedSize` for a first approximation. For anything over a few tens of kilobytes minified+gzipped, justify the weight against the feature or find a lighter path.
- Prefer the platform first: `Intl` for date/number/relative-time formatting, `fetch` over HTTP client libraries, native `structuredClone`, CSS for animation before an animation library. The zero-kilobyte option is competitive surprisingly often.
- When a library is warranted, prefer the lighter peer (`date-fns` or `dayjs` over `moment`) and import so tree-shaking works: named imports from the package root or direct submodule imports — never a namespace import of the whole library for one function.
- Match scope to need: a single sparkline does not justify a full charting framework. Look for the focused package, or the heavyweight's modular entry points, before adopting the whole suite.
- This rule is about browser-bound code. Server-side and build-time dependencies have different economics — don't apply bundle anxiety to a CLI tool, and don't excuse a client package because "it's small on disk."

**Red flags that you're about to violate this:**
- "This is the most popular library for it, so it's the right choice."
- "One dependency won't move the needle on load time."
- "Bundle size is a performance optimization for later."
- "I'll import the whole library; the bundler probably tree-shakes it."
- "The dev server loads instantly, so the size is fine."

---

## Why It Works

1. **It converts size from an attribute into a cost with a payer** — every user, every cold load — which gives the AI a stakeholder to weigh instead of a number to ignore.
2. **It puts the platform check first**, the move that most often eliminates the package entirely, and the one assistants skip because library names are more available than platform APIs.
3. **It addresses the import-style failure separately**, because choosing a tree-shakeable library and then importing it untree-shakeably is its own distinct way to ship the whole thing.
4. **It scopes the rule to browser-bound code explicitly**, preventing the overcorrection where the AI starts agonizing over the size of devDependencies.

## Origin

A marketing site's "latest posts" widget needed relative timestamps, and an assistant added a full-fat date library plus its locale data — roughly seventy kilobytes gzipped for strings like "3 days ago." Two more assistant sessions over the following month added a carousel suite for one image slider and an icon pack imported whole for six icons. The site's mobile performance score dropped enough that the analytics funnel showed it, and the eventual cleanup PR replaced all three additions with platform APIs and inline SVG — a net deletion of about 400 KB nobody had decided to add.
