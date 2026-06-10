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
