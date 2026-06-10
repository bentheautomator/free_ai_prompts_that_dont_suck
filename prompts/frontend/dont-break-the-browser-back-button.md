---
title: Don't Break the Browser Back Button
slug: dont-break-the-browser-back-button
category: frontend
tags: [universal, frontend]
works_with: all
severity: high
one_liner: "Stops UI navigation that the back button can't undo or that traps users"
---

# Don't Break the Browser Back Button

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from building navigation-like UI changes that ignore browser history, or from polluting history so Back stops working.

**[Copy-paste ready version](../../install/dont-break-the-browser-back-button.md)** — just the instruction block, no explanation.

## The Problem

The back button breaks in two opposite ways, and AI assistants commit both. First: navigation that history never hears about. A "multi-step wizard" implemented as `setStep(step + 1)`, a detail view that swaps in via state, a full-screen modal — the user finishes step 3, presses Back to revisit step 2, and is teleported out of the entire flow to whatever page they came from, losing everything. The URL never changed, so the browser had nothing to go back to.

Second: history that gets polluted. A search/filter UI that calls `pushState` (or `router.push`) on every keystroke or checkbox toggle, so escaping the page requires pressing Back fourteen times — one per character typed. Or `redirect`/`replace` misused so Back bounces the user forward again in a loop. Either way, the user's most-trusted button now does something hostile.

Assistants cause this because they evaluate flows forward-only: click, observe, done. Back is a state transition they never simulate. In-component state is also simply easier to write than router integration, and `pushState` vs `replaceState` looks like an interchangeable detail when you've never watched a user mash Back in frustration.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Break the Browser Back Button

ALWAYS decide, for any UI state change, what the back button should do afterward — and make history match that answer. Users treat Back as undo for navigation; UI that feels like navigation must behave like it.

- If a change feels like "going somewhere" — wizard steps, detail views, opened full-screen panels, tab selection that users would deep-link — it belongs in the URL (route or query param) so Back returns to the previous view, not the previous page.
- If a change is rapid-fire refinement — keystrokes in a search box, toggling filters — update the URL with `replaceState` (or the router's `replace: true`) so the state is shareable and reload-safe but doesn't stack a history entry per interaction. One coarse-grained push when the user "commits" (submits, navigates) is fine; one per keystroke is vandalism.
- Modals and drawers: pick one behavior and implement it fully. If Back should close the modal, push an entry on open and close on `popstate`; if not, don't touch history. Never push on open without handling the pop — that strands a junk entry.
- Never chain redirects such that Back lands on a page that immediately re-redirects forward. Use `replace` for the intermediate hop.
- Restore scroll position and state when the user comes Back; if your data refetch resets the list and loses their place, the navigation isn't done.
- Test the flow backward: after every step you build, ask "user presses Back here — where do they land, and did they lose work?"

**Red flags that you're about to violate this:**

- "The wizard step can just live in component state."
- "I'll push a history entry on every filter change so it's all in the URL."
- "Nobody uses the back button inside a flow like this."
- "pushState and replaceState are basically the same thing."
- "The modal closing on Back is a nice-to-have, skip for now."
- "Back works in my flow — I clicked through it forward and it was fine."

---

## Why It Works

1. **It forces the backward simulation the AI never runs.** "Where does Back land after this change?" is a concrete question per interaction; without it, the AI only ever traverses flows forward.
2. **It resolves push-vs-replace with a usable heuristic.** "Feels like going somewhere" vs "rapid refinement" maps the fuzzy decision onto the two failure modes (lost flows vs polluted stacks) directly.
3. **It bans the half-implemented modal pattern.** Pushing on open without handling popstate is the most common partial job and is worse than doing nothing; calling it out closes the middle ground.
4. **It includes state restoration in the definition of working.** Back that technically navigates but dumps the user at the top of a refetched list still reads as broken to users; the rule says so before the AI declares done.

## Origin

A checkout flow was rebuilt by an assistant as a single route with `step` in component state — cleaner, it reasoned, than four routes. Users who pressed Back on the payment step to fix their shipping address were ejected to the cart page with all four steps wiped. Support tickets called it "the checkout that deletes your order." Conversion on the flow dropped measurably until the steps were moved into the URL, which took an afternoon.
