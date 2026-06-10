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
