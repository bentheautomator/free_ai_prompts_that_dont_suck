---
title: Use Real Buttons, Not Clickable Divs
slug: use-real-buttons-not-clickable-divs
category: frontend
tags: [universal, frontend, accessibility]
works_with: all
severity: critical
one_liner: "Stops div-with-onClick fake buttons that keyboards and screen readers can't use"
---

# Use Real Buttons, Not Clickable Divs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from building interactive controls out of `<div onClick>` instead of `<button>`, locking out keyboard and assistive-technology users.

**[Copy-paste ready version](../../install/use-real-buttons-not-clickable-divs.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant for a card with a "dismiss" action, a custom-styled toggle, or anything where the default button chrome would need overriding, and it will frequently produce `<div className="btn" onClick={handleClick}>`. It renders identically to a button. It clicks identically with a mouse. And it is completely invisible to the keyboard: no tab stop, no Enter/Space activation, no `role`, no announced name in a screen reader. The control simply does not exist for a chunk of your users.

The AI does this because the visual outcome is the only outcome it checks, and a div is the path of least resistance — no `appearance` reset, no fighting user-agent styles, no worrying about `type="submit"` side effects inside forms. The training data is also full of div-soup component libraries, so the pattern feels normal. Occasionally the AI "fixes" it by bolting on `role="button"` and `tabIndex={0}` but forgetting the keydown handler, which produces a control that focuses but never activates — arguably worse, because it now fails silently mid-interaction.

This is the textbook accessibility violation auditors look for first, and it fails WCAG without ambiguity. It's also the kind of regression that never appears in mouse-driven QA.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use Real Buttons, Not Clickable Divs

NEVER attach a click handler to a `<div>` or `<span>` to make it act like a button or link. Use `<button>` for actions and `<a href>` for navigation, every time.

A div with `onClick` works only for mouse users. It has no tab stop, no Enter/Space activation, and no role announced to screen readers — the control does not exist for anyone not using a pointer.

- Action that does something on the page → `<button type="button">`. Inside a form, be explicit about `type` so you don't accidentally submit.
- If the button must not look like a button, reset the styles: `button { all: unset; cursor: pointer; }` (then restore `:focus-visible` styling). Restyling is cheap; reimplementing button semantics is not.
- Do not "fix" a clickable div by adding `role="button"` and `tabIndex={0}`. That also requires an `onKeyDown` handler for Enter and Space, plus disabled-state semantics — you are rebuilding `<button>` badly. Just use the element.
- Wrapping a whole card in a click handler: put a real `<button>` or `<a>` inside the card for the action, and expand its hit area with CSS (`::after { position: absolute; inset: 0; }`) instead of making the wrapper interactive.
- When editing existing code that already has clickable divs, flag them as bugs; do not copy the pattern for consistency.

**Red flags that you're about to violate this:**

- "A button would bring default styles I'd have to override, a div is cleaner."
- "The whole card is clickable, so the wrapper div needs the onClick."
- "I'll add role='button' and tabIndex, that makes it accessible."
- "This is just an icon, it doesn't need to be a real button."
- "The existing codebase does it this way, so I'll match the pattern."
- "It works when I click it, so the interaction is done."

---

## Why It Works

1. **It kills the styling excuse with a concrete alternative.** The number-one reason the AI picks a div is avoiding user-agent button styles; giving it `all: unset` removes the only practical justification.
2. **It names the half-fix.** `role="button"` + `tabIndex` without keydown handling is the most common "accessible-looking" failure, and a rule that didn't call it out would get exactly that as a workaround.
3. **It covers the clickable-card case explicitly.** That's where most violations actually happen — not on things called "button" but on cards, rows, and tiles where the interactive wrapper feels natural.
4. **It redefines "works" to include activation paths the AI never tests.** Mouse-click success is the AI's whole evaluation loop; the rule forces Enter, Space, and screen-reader announcement into the definition of done.

## Origin

An assistant was asked to build a settings page with a list of toggleable integration cards. Every card was a `<div onClick>` with a chevron icon; the page looked pixel-perfect and shipped after visual review. A customer using a screen reader reported they could read the integration names but found "no controls anywhere on the page" — the entire settings surface was inert for them. The rewrite touched eleven components because the pattern had been copied into every list item in the app by then.
