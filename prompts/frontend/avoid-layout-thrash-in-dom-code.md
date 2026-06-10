---
title: Avoid Layout Thrash in DOM Code
slug: avoid-layout-thrash-in-dom-code
category: frontend
tags: [universal, frontend]
works_with: all
severity: medium
one_liner: "Stops interleaved DOM reads and writes that force synchronous reflows"
---

# Avoid Layout Thrash in DOM Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from interleaving layout reads and style writes — especially in loops and scroll handlers — forcing the browser to recalculate layout dozens of times per frame.

**[Copy-paste ready version](../../install/avoid-layout-thrash-in-dom-code.md)** — just the instruction block, no explanation.

## The Problem

The browser batches style changes and recalculates layout once per frame — unless your code asks a layout question (`offsetHeight`, `getBoundingClientRect()`, `scrollTop`, `getComputedStyle()`) after a style write, in which case it must stop and synchronously recompute layout to answer truthfully. AI assistants write exactly that pattern, most damagingly in loops: for each list item, read its height, then set a style based on it. Read, write, read, write — every read after a write forces a full reflow, so a 200-item list triggers 200 synchronous layouts in one frame. The page stutters, and on a mid-range phone it freezes.

The same thrash hides in scroll and resize handlers that call `getBoundingClientRect()` per element per event, in "animations" that mutate `style.left` from a `setInterval`, and in measure-then-style logic that ping-pongs across the read/write boundary without noticing it exists. The code is correct — every value read is accurate, every style lands — which is why the AI ships it. Correctness was the only test; the cost per frame was never measured, and locally, on a developer-class machine with twelve list items, it's invisible.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Avoid Layout Thrash in DOM Code

NEVER interleave DOM layout reads and style writes, especially in loops. Batch all reads first, then all writes — reading layout after writing styles forces the browser into a synchronous reflow.

Layout reads include `offsetWidth/Height/Top`, `clientWidth`, `scrollTop/Height`, `getBoundingClientRect()`, `getComputedStyle()`, and `focus()`. Each one issued after a style/DOM write makes the browser recalculate the page on the spot.

- In any loop over elements: phase 1 reads every measurement into an array, phase 2 applies every write. Never measure-and-mutate per iteration.
- Scroll/wheel/resize/pointermove handlers run constantly; they must not measure per event. Cache measurements outside the handler and refresh them only when layout actually changes (use `ResizeObserver`, not a re-measure in the hot path). For visibility checks, use `IntersectionObserver` instead of `getBoundingClientRect()` in a scroll handler.
- Visual updates driven by JS belong in `requestAnimationFrame`, with reads at the top of the frame callback and writes after — never in `setInterval`/`setTimeout`.
- Animate `transform` and `opacity`, which skip layout entirely; animating `top/left/width/height/margin` re-layouts every frame. If CSS transitions/animations can express it, prefer them over JS mutation.
- Before measuring at all, ask if CSS can decide instead: equal heights via flex/grid, sticky positioning via `position: sticky`, truncation via `text-overflow` — most measure-then-set code is reimplementing a CSS feature.
- This applies inside framework code too: a ref-based measure in the same pass as state-driven style changes thrashes identically.

**Red flags that you're about to violate this:**

- "For each item, I'll grab its height and set the style right there."
- "getBoundingClientRect in the scroll handler tells me exactly where it is."
- "setInterval at 16ms is basically requestAnimationFrame."
- "I'll animate the left property, transform math is confusing."
- "It runs fine on my machine with the test data."
- "One extra read in the loop can't matter."

---

## Why It Works

1. **It teaches the invisible cost model.** The AI has no signal that `offsetHeight` is sometimes expensive; naming the write-then-read trigger turns an invisible performance cliff into a recognizable code shape.
2. **It prescribes the mechanical fix.** "Batch reads, then writes" is a transformation the AI can apply without judgment, which beats "be careful about reflows" by a mile.
3. **It redirects to observers and CSS before optimization.** Most thrashing code shouldn't be made faster — it should be deleted in favor of `IntersectionObserver`, `ResizeObserver`, or a CSS feature, and the rule puts that question first.
4. **It pre-empts "fine on my machine."** Twelve items on a dev laptop hides what two hundred items on a phone reveals; calling that rationalization out forces the AI to reason about scale, not the sample.

## Origin

Asked to add scroll-linked reveal animations, an assistant wrote a scroll handler that looped over every card calling `getBoundingClientRect()` and setting `style.top` per card. With the demo's nine cards it was smooth. The production page had 180 cards; scrolling dropped to single-digit FPS on mobile and the feature was reported as "the page that fights you when you scroll." The replacement was one `IntersectionObserver` and a CSS transition — the handler, and the jank, deleted entirely.
