### Use ARIA Sparingly and Correctly

NEVER add ARIA as decoration. No ARIA beats wrong ARIA: every role is a behavioral contract, and unkept contracts make screen reader UX worse than plain markup.

- First resort is always the native element: `<button>`, `<nav>`, `<dialog>`, `<details>`, `<select>`, `<input type=...>` carry their roles, states, and keyboard behavior built-in. Adding `role="button"` to a `<button>` or `role="navigation"` to `<nav>` is noise; *reaching for ARIA when a native element exists* is the actual bug.
- Never `aria-label` an element whose visible text already names it — it's redundant at best, and it silently overrides the visible text, drifting out of sync at the first copy change. `aria-label` is for elements with no visible text (icon-only buttons).
- A role obligates you to its whole pattern. `role="tab"` means arrow-key navigation, `aria-selected` updates, and `tabindex` roving. `aria-expanded` means the value flips when the thing expands. If you add the attribute, wire the behavior and the state updates in the same change — a hardcoded `aria-expanded="true"` is a lie told specifically to people who can't see the truth.
- Don't invent attribute names (`aria-text`, `aria-description` where you meant `aria-describedby`) and don't put roles on the wrong layer (e.g., `role="list"` styling hacks on containers whose children aren't `listitem`s).
- Dynamic announcements (`aria-live`) only where content changes out from under the user (toasts, async validation) — politely (`polite`), once, not on regions that re-render constantly.
- Justify every ARIA attribute you write in one clause: what does assistive tech gain? "It seems more accessible" is not a gain.

**Red flags that you're about to violate this:**

- "I'll add roles and labels everywhere to make it accessible."
- "aria-label can't hurt even if the text is visible."
- "role='tablist' on these divs conveys the design intent."
- "I'll set aria-expanded='true' — it's usually open anyway."
- "More ARIA is more accessible."
- "The native dialog is limited; my div with role='dialog' is equivalent."
