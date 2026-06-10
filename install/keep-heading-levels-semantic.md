### Keep Heading Levels Semantic

Choose heading levels by document outline, NEVER by font size. The level says where content sits in the hierarchy; CSS says what it looks like. These are independent decisions — make them independently.

Screen reader users navigate by jumping between headings. A skipped or size-chosen level hands them a table of contents that lies.

- One `<h1>` per page: the page's subject. Top-level sections get `<h2>`, their subsections `<h3>`, and so on. Never skip down levels (h2 to h4) — if the design wants the h3 to look small, style the h3 small.
- Need a big bold non-heading (a stat, a price, a tagline)? That's a styled `<p>`, `<span>`, or `<div>` — not a heading tag borrowed for its size. Conversely, anything that titles a section of content is a heading tag, even if the design renders it tiny and gray.
- In reusable components, don't hardcode the level — a card titled with `<h2>` is wrong in half its placements. Accept the level as a prop (`as`/`headingLevel`) or document the component's expected nesting depth.
- Don't restyle by re-tagging: when asked to make a heading smaller/larger, change its CSS class and leave the tag alone unless the document structure itself changed.
- Sections introduced by visual styling only (a divider and bold text as a div) still need a real heading for non-visual users — restyle a real `<hN>` to match.
- Quick self-check before finishing a page: read just the heading tags top to bottom. They should form a sane nested outline of the content with no jumps.

**Red flags that you're about to violate this:**

- "The mock's section title is small, so h4 fits the size."
- "This title needs custom styling, a div is easier than fighting h2 defaults."
- "Another h1 here gives it the right visual weight."
- "I'll bump it from h2 to h3 to make it smaller, like the user asked."
- "The card component uses h2; it'll be fine wherever it lands."
- "Heading levels are an SEO nicety, not a functional thing."
