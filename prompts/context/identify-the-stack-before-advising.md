---
title: Identify the Stack Before Advising
slug: identify-the-stack-before-advising
category: context
tags: [universal, assumptions, grounding]
works_with: all
severity: high
one_liner: "AI assuming Next.js from one .tsx file or Django from one .py file"
---

# Identify the Stack Before Advising

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from inferring the whole framework stack from one weak signal and tailoring everything to the wrong stack.

**[Copy-paste ready version](../../install/identify-the-stack-before-advising.md)** — just the instruction block, no explanation.

## The Problem

One `.tsx` file, and the AI decides it's a Next.js app — suggesting `getServerSideProps`, App Router file conventions, and `next/image` to what is actually a Vite SPA. A `.py` file, and suddenly the advice assumes Django — `settings.py`, the ORM, `manage.py` commands — for a FastAPI service. The inference runs from a weak signal (a file extension, one import, the language) to a strong conclusion (the entire framework, with all its conventions), because in the training data, the popular framework is the statistically safe completion.

Stack misidentification poisons everything downstream, and it persists. Once the AI has decided "this is Next.js," every subsequent answer inherits the error: routing advice for the wrong router, data-fetching patterns for the wrong rendering model, deployment guidance for the wrong platform, env-var conventions (`NEXT_PUBLIC_*`) for a bundler that wants `VITE_*`. The user corrects one wrong suggestion and gets another from the same wrong premise, because the misidentification — never stated outright — was never corrected.

The actual stack is declared in the manifest, the config files at the repo root, and the imports. It is the most knowable fact about a project, and it determines the correctness of nearly all advice that follows.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Identify the Stack Before Advising

NEVER infer a project's framework or stack from a weak signal — a file extension, the language, a single familiar-looking file. React is not Next.js; Python is not Django; a `.tsx` file is not a verdict. Identify the stack from its declarations before giving stack-specific advice.

A misidentified stack poisons every downstream answer, because the wrong premise is inherited silently by all of them.

**Before stack-specific suggestions:**
- Read the manifest's dependencies — the framework is named there: `next` vs `vite` vs `react-scripts`, `django` vs `fastapi` vs `flask`, `rails` vs `sinatra`, `spring-boot` vs bare servlet
- Confirm with root config files: `next.config.*`, `vite.config.*`, `nuxt.config.*`, `angular.json`, `manage.py`, `artisan`, `Gemfile` — each is a framework signature
- Distinguish library from meta-framework: React/Vue/Svelte alone vs Next/Nuxt/SvelteKit changes routing, rendering, data fetching, and env-var conventions — verify which layer exists before advising on any of it
- Identify the secondary stack too, where relevant: bundler, ORM, state manager, CSS approach — each has the same "popular default" trap
- State your identification once, early: "this is a Vite + React SPA with TanStack Router" — so a wrong read gets corrected at the premise, not rediscovered one bad suggestion at a time
- If signals conflict (a `next.config.js` and a `vite.config.ts` in one repo), investigate — migration in progress, monorepo, or leftovers — instead of picking the framework you know better

**Red flags that you're about to violate this:**
- "It's React, so Next.js conventions apply..."
- "Python web service — Django patterns it is..."
- "They'll be using the framework everyone uses for this..."
- "The file structure looks Next-ish, close enough..."
- "I'll suggest the idiomatic approach" — idiomatic for which framework, verified how?
- Giving routing, rendering, or deployment advice without having read the manifest's dependencies

---

## Why It Works

1. **It breaks the weak-signal-to-strong-conclusion inference.** Naming the exact bad syllogism ("React is not Next.js") gives the AI a pattern to catch in its own reasoning before the conclusion hardens.

2. **It makes the premise explicit and correctable.** Stating the identification early converts a silent assumption into a visible claim the user can veto in five words — once — instead of debugging its consequences indefinitely.

3. **It targets the library/meta-framework boundary.** That's where most misidentification lives and where the advice diverges hardest; making it a named checkpoint focuses verification where errors concentrate.

4. **It handles conflicting signals without defaulting to popularity.** "Investigate, don't pick the one you know better" closes the tiebreaker loophole through which the statistically-popular framework always wins.

## Origin

A developer asked how to add authenticated server-side data fetching. Their AI, having seen React components, delivered a thorough Next.js answer: middleware, server components, `cookies()` from `next/headers`. The project was a Vite SPA with an Express API — there was no server rendering to fetch on. The developer, new to frontend, spent two days trying to make the advice fit, including almost migrating the build to Next.js to "unlock" the suggested approach. The manifest that named `vite` and `express` had 38 lines, none of which said `next`.
