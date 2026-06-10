---
title: Respect prefers-reduced-motion
slug: respect-prefers-reduced-motion
category: frontend
tags: [universal, frontend, accessibility]
works_with: all
severity: medium
one_liner: "Stops animations that ignore the OS-level reduced motion setting"
---

# Respect prefers-reduced-motion

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping parallax, auto-playing carousels, and large-movement animations that ignore the user's reduced-motion preference.

**[Copy-paste ready version](../../install/respect-prefers-reduced-motion.md)** — just the instruction block, no explanation.

## The Problem

Asked to "add some polish," an AI assistant delivers: cards that slide in on scroll, a parallax hero, a bouncing notification badge, page transitions that zoom. Every animation unconditional, because the request was for motion and motion is what got built. Meanwhile a measurable slice of users has `prefers-reduced-motion: reduce` set at the OS level — many because animation physically affects them. Vestibular disorders turn parallax and zoom into genuine dizziness and nausea; for others it's migraines or attention disruption. The setting exists, the CSS media query to honor it exists, and the AI knows both — it just never connects them to the animation it's currently writing, because nothing in its render-and-admire evaluation has an OS preferences panel.

The subtler version: the codebase *has* a reduced-motion convention (a global media query, a `useReducedMotion` hook, a Framer Motion config), and the AI's new animation bypasses it — raw `animate-bounce`, a hand-rolled `@keyframes`, a JS-driven scroll effect — so the app's accessibility guarantee silently develops holes exactly where the newest features are.

This isn't about banning animation. Honoring the preference usually costs four lines, and the reduced variant (fade instead of slide, instant instead of zoom) is often barely distinguishable to everyone else.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Respect prefers-reduced-motion

EVERY animation you ship must honor `prefers-reduced-motion`. Motion that ignores the setting makes users with vestibular disorders physically ill; the fix costs a media query.

- First check whether the project already has a reduced-motion mechanism — a global CSS block, a `useReducedMotion` hook, an animation-library config (`MotionConfig reducedMotion="user"`). If it exists, route your animation through it; an animation that bypasses the house mechanism is a regression even if it's pretty.
- Otherwise, pair the animation with its query. Either wrap the motion: `@media (prefers-reduced-motion: no-preference) { .card { animation: slide-in .3s; } }`, or neutralize it: `@media (prefers-reduced-motion: reduce) { .card { animation: none; transition: none; } }`. For JS-driven motion, gate on `matchMedia('(prefers-reduced-motion: reduce)').matches`.
- Reduce means reduce, not necessarily remove: cross-fades and opacity changes are generally fine; what must go is movement — sliding, zooming, parallax, spinning, bouncing. Swap the slide-in for a fade-in and most users can't tell you changed anything.
- The worst offenders need special attention: parallax scrolling, scroll-jacking, auto-playing carousels, full-screen page transitions, and infinite/looping ambient motion. If reduced-motion is set, these should be fully static.
- Auto-playing motion (carousels, marquee tickers, background video) additionally needs a visible pause control regardless of the preference — auto-motion that can't be stopped fails WCAG 2.2.2 for everyone, not just reduced-motion users.
- Loading spinners and progress indicators are conventionally exempt (they communicate state), but keep them small and contained.

**Red flags that you're about to violate this:**

- "The user asked for animations, reduced-motion wasn't mentioned."
- "I'll add the parallax now; the media query can come in a polish pass."
- "It's a subtle slide, nobody gets sick from 20 pixels."
- "The animation library probably handles the preference automatically."
- "Wrapping every animation in a query doubles the CSS."
- "This carousel auto-advances, that's the whole point of it."

---

## Why It Works

1. **It attaches the query at write time, not audit time.** The failure mode is animations and the preference living in separate mental files; making the media query part of "an animation" as a unit closes the gap permanently.
2. **It checks for house plumbing first.** In codebases with an existing mechanism, the harm is bypass, not absence — and an AI told only "add media queries" would create a parallel system instead of joining the existing one.
3. **It defines reduce as fade-not-move.** AIs that interpret the preference as "delete all animation" produce a degraded experience and resist the rule; the swap recipe makes compliance nearly free aesthetically.
4. **It verifies the library assumption.** "Framer/GSAP probably handles it" is usually false by default; naming the rationalization forces the one-line config check instead of the hope.

## Origin

A fintech dashboard got a celebratory redesign: numbers that counted up, cards that slid in cascades, a parallax header. A user with a vestibular disorder wrote support that checking their balance now required closing their eyes while the page loaded, and that they'd be switching banks over it. The reduced-motion variant — fades only — took one engineer one afternoon, and in user testing nobody without the OS setting could identify what had changed.
