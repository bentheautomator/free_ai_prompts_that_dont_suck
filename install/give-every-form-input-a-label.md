### Give Every Form Input a Label

EVERY form control gets a programmatically associated label. A placeholder is not a label — it disappears on input and is unreliable for assistive tech.

- Default pattern: `<label htmlFor="email">Email address</label><input id="email" />`, or wrap the input inside the label. The `id` must be unique on the page (in reusable components, generate it — `useId` — don't hardcode it).
- The design shows no visible label? Use a visually-hidden label (the project's `.sr-only`/`.visually-hidden` class) or `aria-label="Email address"` — not nothing. Minimal design is a styling decision, not a semantics decision.
- Placeholders are for format hints (`placeholder="name@example.com"`), supplementary to a label, never instead of one.
- Checkboxes and radios especially: the clickable text next to them must be their real `<label>`, both for screen readers and because it makes the text a click target — a bare `<span>` next to a checkbox is two bugs.
- Selects, textareas, and custom widgets (comboboxes, date pickers) follow the same rule; for custom widgets, ensure the visible label is wired via `aria-labelledby` to the focusable element.
- Verify the association the cheap way: clicking the label text must focus (or toggle) the control. If it doesn't, the wiring is broken regardless of how it looks.
- Group related controls: radio groups and checkbox sets get a `<fieldset>` with a `<legend>` naming the question, or the individual options read as context-free fragments.

**Red flags that you're about to violate this:**

- "The placeholder says what the field is, that's the label."
- "The mock has no labels, so the form has no labels."
- "I'll add the label element; wiring the for attribute is just ceremony."
- "It's one search box, everyone knows what it's for."
- "I'll reuse id='input' like the other instances do."
- "The checkbox text is right next to it, the association is obvious."
