---
title: Prevent SSR Hydration Mismatches
slug: prevent-ssr-hydration-mismatches
category: frontend
tags: [universal, frontend, react]
works_with: all
severity: high
one_liner: "Stops Date.now, random values, and window checks from breaking hydration"
---

# Prevent SSR Hydration Mismatches

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from rendering server/client-divergent values — time, randomness, locale, window — that make hydration fail or silently rebuild the DOM.

**[Copy-paste ready version](../../install/prevent-ssr-hydration-mismatches.md)** — just the instruction block, no explanation.

## The Problem

In a server-rendered app, the AI writes `Hello, {new Date().getHours() < 12 ? 'morning' : 'afternoon'}` or gives a list item `id={Math.random()}` or formats a price with `toLocaleString()` using the runtime's default locale. Each renders fine in isolation — and each produces different output on the server than on the client, because the server rendered at a different millisecond, with a different random seed, in a different locale and timezone. Hydration compares the two trees, finds the mismatch, logs a warning nobody reads, and in newer React versions throws away the server HTML and re-renders the whole tree client-side: visible content flicker, lost SSR benefit, and occasionally events bound to the wrong nodes.

The other classic is `if (typeof window !== 'undefined')` used to branch *rendered output* — `return window.innerWidth < 768 ? <Mobile/> : <Desktop/>`. The server takes one branch, the client takes the other, and the trees disagree by construction. The AI reaches for this because the `window is not defined` crash is loud and the typeof check makes it go away; the hydration mismatch it creates is quiet.

Assistants produce these because they develop and reason against a client-only mental model. The code is correct in a SPA. SSR makes "what did the server render?" part of correctness, and nothing in the local file says so.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Prevent SSR Hydration Mismatches

In server-rendered apps, NEVER render output that can differ between the server pass and the first client render. The two trees must match byte-for-byte; anything time-, random-, locale-, or window-dependent breaks that.

- No `Date.now()`, `new Date()`, `Math.random()`, or `crypto.randomUUID()` in render output. Compute timestamps/ids on the server (pass as props), in event handlers, or in an effect after mount.
- Stable ids for elements: use the framework's facility (`useId` in React), never `Math.random()` keys or ids.
- Never branch rendered output on `typeof window !== 'undefined'` or `navigator.*`. The server and client will take different branches by definition. Render the universal version, then adapt after mount (effect + state), or use the framework's client-only escape hatch (`dynamic(..., { ssr: false })`, `<ClientOnly>`).
- Locale/timezone formatting (`toLocaleString`, `Intl.*`) must use an explicit locale and timezone passed from a single source — the server's defaults and each visitor's browser defaults differ.
- Relative time ("3 minutes ago") drifts between passes; render a stable absolute form on the server and upgrade it client-side, or suppress warnings only for that text node if the framework supports it.
- Anything read from `localStorage` or matchMedia for the initial render (theme, viewport) must have a deterministic server fallback; apply the stored preference after mount or via an inline pre-hydration script, per the project's existing pattern.

**Red flags that you're about to violate this:**

- "window is undefined on the server, I'll guard the JSX with typeof window."
- "Math.random() is a quick unique id for this element."
- "toLocaleString with no arguments will use the user's locale, perfect."
- "I'll read the theme from localStorage in the component body."
- "The timestamp only differs by milliseconds, close enough."
- "It renders fine in my mental browser, hydration will be fine."

---

## Why It Works

1. **It reframes the typeof-window guard as the bug, not the fix.** The AI deploys that guard to silence a crash and believes it solved SSR; naming it as a guaranteed-mismatch pattern breaks the false sense of completion.
2. **It enumerates the divergence sources.** Time, randomness, locale, viewport, storage — the AI can audit a render function against a five-item list far more reliably than against the abstract idea of determinism.
3. **It pairs every ban with the sanctioned alternative.** `useId`, effect-after-mount, explicit locale, client-only wrappers — when the right move is named, the AI doesn't improvise a worse one.
4. **It counters "close enough" for timestamps.** Hydration comparison is exact; stating byte-for-byte equality removes the rationalization that small drift is tolerable.

## Origin

A marketing site's hero said "Good morning" or "Good evening" based on `new Date().getHours()`, added by an assistant asked to "make the greeting friendlier." The server, in UTC, rendered one greeting; visitors' browsers rendered another, and the framework responded to the mismatch by client-re-rendering the entire page — every visitor saw the full hero flash and re-layout on load. It was diagnosed weeks later from a pile of ignored hydration warnings, and fixed by rendering a neutral greeting on the server and upgrading it in an effect.
