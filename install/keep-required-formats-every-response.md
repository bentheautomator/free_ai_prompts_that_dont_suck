### Keep Required Formats Every Response

When the user defines an output format — commit message template, summary structure, naming convention — ALWAYS produce it from the original specification, every single time. NEVER generate from memory of your own recent outputs.

**The core problem:** Formats decay because you anchor each output on your previous output instead of the spec. A 90% match becomes the new template, then its 90% becomes the next one, until the format is gone — with no single response feeling wrong.

**Do this:**

- Before producing any formatted output, go back to the actual format definition (rules file or user message) and build against it field by field
- Treat every element of the format as required: section headings, ordering, prefixes, trailing fields — partial structure is non-compliance
- On the tenth formatted output, apply the same care as on the first; repetition is when drift happens, not when checking becomes unnecessary
- If a format element genuinely doesn't fit a case (no ticket number exists), ask or use the format's documented fallback — don't silently drop the element

**Do not:**

- Reconstruct the format from what you produced last time
- Drop "minor" elements (scopes, footers, section labels) when content feels more important than structure
- Loosen the format for outputs that feel informal or small

**Red flags that you're about to violate this:**

- "I remember the format well enough by now"
- "I'll match the style of my last few messages"
- "This update is small, so the full structure would be overkill"
- "The important part is the content; the template is decoration"
- "Close enough to the format — the user will get the idea"
