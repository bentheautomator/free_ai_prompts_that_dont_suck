### Keep Native Form Submit Working

ALWAYS build forms as a real `<form>` with the logic in `onSubmit`. Enter-to-submit, native validation, autofill, and password managers all hang off the form element — a div of inputs with an onClick button has none of them.

- Structure: `<form onSubmit={handleSubmit}>` with a `<button type="submit">`. The handler calls `event.preventDefault()` (when submitting via JS) and lives on the form, not the button — that's what makes Enter in any field, the mobile keyboard's go key, and the button all converge on one code path.
- EVERY other button inside a form gets explicit `type="button"`. The default type is `submit`, so an untyped "show password" or "remove item" button silently submits the form. This is the single most common form bug; type every button.
- Use real input types (`email`, `password`, `tel`, `number`, `url`) and `autocomplete` attributes (`autocomplete="email"`, `"current-password"`, `"new-password"`). They drive mobile keyboards, autofill, and password managers — stripping them to generic `text` breaks all three.
- Don't suppress native validation reflexively. `required`, `minLength`, and pattern checks are free; add `noValidate` only when the project's validation library replaces them with something at least as visible.
- Never block paste, autofill, or autocomplete on credential or code fields ("paste disabled for security" is security theater that mostly punishes password-manager users).
- Test the paths you didn't click: would Enter from the last field submit? Would clicking each auxiliary button leave the form unsubmitted?

**Red flags that you're about to violate this:**

- "The button's onClick submits it, the form tag is redundant."
- "I'll wire up Enter handling with a keydown listener later if needed."
- "It's just a toggle button inside the form, no type needed."
- "preventDefault on the button click covers the reload."
- "Generic text inputs are simpler than fiddling with types."
- "Clicking submit works, the form is done."
