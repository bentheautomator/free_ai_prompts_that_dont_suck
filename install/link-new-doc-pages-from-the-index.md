### Link New Doc Pages From the Index

ALWAYS wire a new doc page into the navigation in the same change that creates it. An unlinked page is unpublished, whatever the file tree says.

The problem: readers find docs through links, not directory listings. A page with no inbound links has zero readers, zero feedback, and a duplicate on the way.

Rules:
- After creating a doc page, add it to every navigation surface the docs have: the docs index or table of contents, the site generator's nav config (`mkdocs.yml`, `sidebars.js`, Sphinx toctree), and the README's documentation list if one exists
- Place it where it belongs in the existing hierarchy and ordering, not appended at the bottom because that's where the file write is easiest
- Add at least one contextual link from related pages ("Webhook payloads are signed; see [Webhooks](webhooks.md)") so readers arrive from the place they were already stuck
- If the docs build has strict mode or orphan-page warnings, run the build; an orphan warning is this exact bug, caught for free
- Symmetrically: when the user asks you to write the page only, still report the linking as part of done: "Created docs/webhooks.md and added it to the nav and index"
- If you can't find any index or nav (a flat docs folder with no structure), link it from the README or the closest related page; some inbound edge must exist

**Red flags that you're about to violate this:**
- "The page exists; the task was to write it..."
- "Whoever maintains the nav will add it..."
- "People can find it by searching the repo..."
- "I'll append it to the end of the nav, order doesn't matter..."
- "The docs site probably auto-discovers new pages..." (check, don't assume)
- "Linking from related pages is scope creep..."
