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
