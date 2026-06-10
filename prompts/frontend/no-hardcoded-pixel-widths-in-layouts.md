---
title: No Hardcoded Pixel Widths in Layouts
slug: no-hardcoded-pixel-widths-in-layouts
category: frontend
tags: [universal, frontend, css]
works_with: all
severity: high
one_liner: "Stops fixed-pixel sizing that shatters layouts on any other screen"
---

# No Hardcoded Pixel Widths in Layouts

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from sizing layout containers in fixed pixels that only fit the one viewport it imagined.

**[Copy-paste ready version](../../install/no-hardcoded-pixel-widths-in-layouts.md)** — just the instruction block, no explanation.

## The Problem

"Make the sidebar wider" becomes `width: 347px`. "Center the form" becomes `width: 600px; margin: 0 auto`. "Fix the card alignment" becomes `height: 412px` because that's how tall the tallest card happened to be with the sample data. AI assistants size things in absolute pixels measured against one imagined desktop viewport and one set of test content, and the layout works exactly there. At 375px wide the 600px form forces horizontal scroll. With real user data the 412px card clips its text mid-sentence. With the browser font size bumped to 125%, everything overflows its fixed box.

The AI does this because pixels are the most direct translation of "what I see" into code — the screenshot it's reasoning about has exact dimensions, so the CSS gets exact dimensions. Flexible sizing requires thinking about content and viewport ranges the AI was never shown. Fixed heights are the worst offenders: they encode an assumption about content length that real data violates on day one, and the overflow is usually hidden or clipped so the bug ships silently.

This isn't a ban on px as a unit — borders, icon sizes, and max-widths are fine in pixels. It's a ban on pixel values doing a layout job that the content or viewport should be doing.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Hardcoded Pixel Widths in Layouts

NEVER give a layout container a fixed pixel width or height sized to fit specific content or a specific viewport. Size layouts so content and screen dimensions drive them.

A fixed `width: 600px` works on exactly one class of screen; a fixed `height: 400px` works for exactly one length of content. Both are bugs waiting for real data.

- Containers that should fill available space: use `flex`/`grid` with `fr`, `flex-grow`, or percentages — not a pixel width that happens to match the current parent.
- Containers that should cap their growth: `max-width` (in `px`, `ch`, or `rem`), never bare `width`. `max-width: 600px; width: 100%` is the centering pattern; `width: 600px` is the broken one.
- Heights: almost never fix them. Let content define height; use `min-height` if you need a floor. If you're setting `height` to make boxes in a row match, use flex/grid alignment (`align-items: stretch`) instead.
- Don't transcribe magic numbers from a screenshot (`width: 347px`, `margin-left: 23px`). If a number has no reason, the layout system is doing the wrong job.
- Text containers: prefer `ch`/`rem` so they scale with user font-size settings; a pixel-fixed box clips text the moment someone zooms.
- If you add a fixed dimension, you must be able to say what guarantees the content fits — and "it fits the sample data" is not a guarantee.

**Red flags that you're about to violate this:**

- "The design shows the sidebar at 280px, so width: 280px."
- "I'll set the height so all the cards line up."
- "600px looks centered on my mental viewport."
- "The text fits in 340px right now."
- "I'll fix the overflow later with overflow: hidden."
- "Pixel values are more predictable than percentages."

---

## Why It Works

1. **It separates px-the-unit from px-the-layout-strategy.** A blanket "don't use pixels" rule gets ignored as impractical; this targets the actual failure — pixels doing flexbox's job.
2. **It supplies the correct pattern at the moment of temptation.** `max-width` + `width: 100%` is the answer to nearly every "fixed width for centering" instinct, and naming it makes the right move as cheap as the wrong one.
3. **It singles out fixed heights.** Height hardcoding is the most damaging variant because content-length assumptions always break, and clipped overflow hides the breakage from review.
4. **It demands a fit guarantee for any fixed dimension.** Forcing the AI to articulate why content can't overflow converts "it fits the sample" from a justification into a recognized red flag.

## Origin

An assistant was asked to "tidy up" a dashboard's stat cards so they aligned in a row. It measured the tallest card and set `height: 180px` on all of them, plus `width: 940px` on the row container to match the design mock. The demo looked immaculate. In production, a German-language user's translated labels wrapped to three lines and got clipped mid-word, and every laptop narrower than 1024px got a horizontal scrollbar. The eventual fix was eight characters of grid CSS replacing forty lines of measurements.
