---
title: Never Remove Focus Outlines
slug: css-never-remove-focus-outlines
category: frontend
tags: [universal, frontend, accessibility]
works_with: all
severity: critical
one_liner: "Stops outline: none from making keyboard navigation invisible"
---

# Never Remove Focus Outlines

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting focus indicators because a designer (or the AI itself) thought the blue ring looked ugly.

**[Copy-paste ready version](../../install/css-never-remove-focus-outlines.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant to "clean up this button's styles" or "remove that blue ring around the input" and it will happily write `outline: none` or `:focus { outline: 0 }`, often in a global reset where it nukes the focus indicator for every element on the page. Mouse users never notice. Keyboard users now have no idea where they are. Tab through the page and the focus is somewhere, but visually nothing changes; the site has become unusable for anyone who can't or doesn't use a pointer.

Assistants do this because the request is framed as visual polish and the result looks correct in the one way they evaluate it: a mouse-driven screenshot of the resting state. The focus outline only exists in a state the AI never inspects. It's also a pattern with enormous training-data gravity, since `*:focus { outline: none }` appears in thousands of old CSS resets.

This isn't cosmetic. Visible focus indication is a WCAG requirement (2.4.7), and "we shipped a UI you cannot operate by keyboard" is the kind of regression that shows up in accessibility audits and legal complaints, not in code review.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Remove Focus Outlines

NEVER write `outline: none`, `outline: 0`, or `box-shadow: none` on a `:focus` state without providing a replacement focus indicator in the same rule. No exceptions for "the designer doesn't like it."

The default outline is the only thing telling keyboard users where they are. Removing it without a substitute makes the page unnavigable for them, and it's invisible in mouse-based testing.

- If the default outline clashes with the design, restyle it; don't delete it. Replace with a visible custom indicator: `outline: 2px solid <color>; outline-offset: 2px;` or an equivalent high-contrast `box-shadow` ring.
- Use `:focus-visible` instead of `:focus` to hide the ring for mouse clicks while keeping it for keyboard focus. That solves the "ugly ring on click" complaint without harming anyone: `button:focus-visible { outline: 2px solid currentColor; }`
- Never put focus-outline removal in a global reset (`*:focus`, `a:focus`, `button:focus`). One global line breaks the entire site.
- A custom indicator must be visible against the actual background: minimum 2px, contrast it against the surface it sits on, and check it on both light and dark variants if the app has them.
- When touching any existing stylesheet, treat an existing `outline: none` without a replacement as a bug worth flagging, not a convention to copy.

**Red flags that you're about to violate this:**

- "The user said the ring looks ugly, so I'll remove the outline."
- "I'll add `outline: none` to the reset for a cleaner baseline."
- "This button has a hover style, so focus styling is redundant."
- "Nobody tabs through this part of the UI anyway."
- "The existing CSS already removes outlines elsewhere, so I'll match it."
- "I'll remove it now and we can add a custom indicator later."

---

## Why It Works

1. **It reframes the request the AI actually receives.** "Remove the ugly ring" gets translated into "restyle the indicator," which satisfies the user's aesthetic complaint without destroying the function. `:focus-visible` is named explicitly because it is the correct answer to the complaint 95% of the time.
2. **It forbids the global-reset form by name.** The single most damaging variant is `*:focus { outline: none }` in a reset file, and a rule that only said "keep focus indicators" would still let the AI copy that line "for consistency."
3. **It blocks the deferral loophole.** "Remove now, restyle later" is how the regression actually ships; requiring the replacement in the same rule makes the safe path the only path.
4. **It redefines "looks right" to include a state the AI never screenshots.** Focus styling only exists under keyboard interaction, so the rule forces consideration of a state outside the default evaluation loop.

## Origin

A team asked their assistant to make form inputs match a new design system. The assistant added the new border styles and, noticing the default focus ring clashed with them, added `input:focus, button:focus, a:focus { outline: none; }` to the global stylesheet as part of the "cleanup." The change passed visual review because every reviewer used a mouse. It was caught three weeks later by an external accessibility audit, by which point the pattern had been copied into two more component files.
