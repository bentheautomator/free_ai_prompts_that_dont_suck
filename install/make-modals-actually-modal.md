### Make Modals Actually Modal

A modal is a behavior contract, not a styled overlay. NEVER ship a dialog that doesn't trap focus, close on Escape, and render the background inert.

- First choice: the project's existing modal/dialog component or library primitive — never a new bespoke overlay div beside an established one. Second choice: native `<dialog>` with `showModal()`, which provides focus trapping, Escape handling, background inertness, top-layer rendering, and `::backdrop` for free.
- If you must hand-roll, the contract has six clauses, all mandatory:
  1. On open, focus moves into the dialog (the first focusable control, or the dialog itself with `tabindex="-1"`).
  2. While open, Tab and Shift+Tab cycle within the dialog only — focus never reaches the background. Use the `inert` attribute on the page content behind, or a focus trap.
  3. Escape closes it (unless mid-destructive-action, in which case it asks).
  4. On close, focus returns to the element that opened it — not to `<body>`.
  5. Background scroll is locked while open (`overflow: hidden` on the scroll container, with scrollbar-width compensation if the layout shifts).
  6. `role="dialog"`, `aria-modal="true"`, and an accessible name (`aria-labelledby` pointing at the title) so screen readers announce the context switch.
- Backdrop-click-to-close: match the project's convention, but never make it the *only* close affordance — a visible close button is required.
- Render the dialog in a portal/top layer, not inside an `overflow: hidden` or transformed ancestor that will clip it.
- These requirements apply to anything claiming modality: dialogs, drawers, full-screen takeovers, lightboxes. (Non-modal popovers — menus, tooltips — have different rules; don't focus-trap those.)

**Red flags that you're about to violate this:**

- "A fixed-position div with a backdrop is a modal."
- "Focus management is a follow-up; the dialog opens and closes fine."
- "Escape handling is a nice-to-have for power users."
- "Nobody will notice the page behind still scrolls."
- "The dimmed backdrop makes it obvious you can't use the background."
- "The native dialog element is too new to rely on."
