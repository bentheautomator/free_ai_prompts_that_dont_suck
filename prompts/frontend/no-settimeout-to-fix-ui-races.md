---
title: No setTimeout to Fix UI Races
slug: no-settimeout-to-fix-ui-races
category: frontend
tags: [universal, frontend]
works_with: all
severity: high
one_liner: "Stops arbitrary delays papering over timing bugs that return under load"
---

# No setTimeout to Fix UI Races

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "fixing" timing-dependent UI bugs with `setTimeout(fn, 100)` instead of finding the event or signal it should actually wait for.

**[Copy-paste ready version](../../install/no-settimeout-to-fix-ui-races.md)** — just the instruction block, no explanation.

## The Problem

A scroll-to-element runs before the element renders. Focus lands on a modal input that doesn't exist yet. A measurement reads zero because the content hasn't laid out. The AI's diagnosis is correct — "this runs too early" — and its fix is `setTimeout(() => { ... }, 100)`. The bug disappears on the machine in the AI's head, so the fix is validated. But 100ms isn't a synchronization point; it's a bet that the thing being waited for always takes less than 100ms. On a throttled CPU, a slow network, a heavy page, or just an unlucky GC pause, the bet loses, and the bug returns — now intermittent, unreproducible, and decorated with a comment like `// wait for render`.

These timeouts metastasize. The 100ms that mostly works becomes 300ms "to be safe," which becomes a visible lag users feel on every interaction even when the wait was unnecessary. Nested timeouts appear when two things race. Test suites inherit the flakiness. And the original question — *what specific event does this code need to happen after?* — remains unanswered, because the timeout made answering it optional.

Assistants reach for the timer because it's a universal hammer: it requires zero understanding of why the timing is off, and it appears to work in any single evaluation. Every real fix requires naming the actual dependency; the timeout requires only a number.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No setTimeout to Fix UI Races

NEVER fix a timing or ordering bug with an arbitrary delay. Name the event you're actually waiting for and hook into it — a magic number is a race condition with a comment.

`setTimeout(fn, 100)` means "I bet this always takes under 100ms." Slow devices, throttled tabs, and heavy pages take the other side of that bet and win.

- Waiting for a render/DOM update: use the framework's post-render hook — an effect (`useEffect` runs after commit), `nextTick`/`afterUpdate`, or a ref callback that fires when the node attaches. Refs + effects replace nearly every "wait for the element" timeout.
- Waiting for an element to appear/resize outside your render control: `MutationObserver` / `ResizeObserver`, disconnected once satisfied. Not a polling loop, not a delay.
- Waiting for layout before measuring/scrolling: `requestAnimationFrame` (or double-rAF for after-paint) waits exactly one frame, not a guessed number of milliseconds.
- Waiting for data or an animation: await the promise; listen for `transitionend`/`animationend` or use the animation API's `finished` promise. The completion signal exists — use it.
- Sequencing two of your own operations: restructure so the second is *called* by the completion of the first (callback, await, state change), instead of both being fired and hoped into order.
- `setTimeout(fn, 0)` to "push past" some unspecified work is the same bug in minimal form: you still haven't named what you're yielding to. Justify any surviving timeout with a comment naming the real awaited condition and why no signal for it exists — UX-intent delays (debounce, toast auto-dismiss) are fine; synchronization delays are not.

**Red flags that you're about to violate this:**

- "A small delay gives the DOM time to update."
- "100ms wasn't enough sometimes, I'll make it 500."
- "setTimeout zero pushes it to the end of the queue, which should be after... whatever needs to happen."
- "It's flaky, so I'll wrap it in another timeout."
- "I can't tell what it's waiting on, but the delay makes it pass."
- "The animation is 300ms, so I'll setTimeout 300 to match."

---

## Why It Works

1. **It converts the fix into a naming exercise.** "What event are you waiting for?" has a real answer in every case (commit, paint, mutation, transitionend, promise), and once named, the correct API is obvious — the timeout survives only while the dependency stays anonymous.
2. **It maps each wait-type to its signal.** The AI often doesn't know `ResizeObserver` or double-rAF exist for these jobs; the table makes the right tool as available as the wrong one.
3. **It calls out the duration-matching trap.** Timing a delay to an animation's configured duration breaks the moment someone edits the CSS; `transitionend` can't drift. Naming this variant blocks the most defensible-looking timeout.
4. **It separates UX delays from sync delays.** Debounce and toast timers are legitimate, and a blanket ban would get the rule ignored; the comment requirement keeps the legitimate cases while exposing the disguised races.

## Origin

A support app's "jump to first unread" feature scrolled before the message list finished rendering, so an assistant wrapped it in `setTimeout(..., 150)`. It worked in every demo. Agents with thousand-message threads on aging hardware landed mid-list instead, and the bug was reported — and closed as unreproducible — four times, because it never failed on a dev machine. The eventual fix was a ref callback on the unread marker that scrolled when the node mounted: no number, no race, and the four duplicate tickets finally died.
