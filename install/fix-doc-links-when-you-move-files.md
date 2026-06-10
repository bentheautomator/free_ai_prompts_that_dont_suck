### Fix Doc Links When You Move Files

ALWAYS update every reference to a file you move or rename, in the same change as the move. A move is not complete when the file arrives; it's complete when nothing points at where it used to be.

The problem: links to docs live in prose, comments, templates, and configs that no tool checks, so a clean-looking move leaves a trail of silent 404s.

Rules:
- After moving or renaming any file, search the whole repo for its old path and old filename: Markdown links, HTML hrefs, code comments, docstrings, issue/PR templates, mkdocs/docusaurus/sphinx navs and sidebars, CI configs, badge URLs
- Search for the bare filename too, not just the full path; relative links (`../setup.md`) won't match a full-path search
- If you moved a heading or renamed it during the move, check anchor links (`#old-heading-slug`) separately; they break without breaking the file link
- Update the doc site's nav/sidebar config if one exists; an unrouted page is broken even with valid links
- For paths likely referenced outside the repo (published docs, wikis, pinned links), mention this to the user; consider a redirect or a stub if the ecosystem supports it
- Run the repo's link checker if it has one. If it doesn't, your grep is the link checker

**Red flags that you're about to violate this:**
- "The move itself was the task; links are cleanup..."
- "I updated the links in the files I had open..."
- "Relative links probably still resolve..." (from a different directory, they don't)
- "Nobody links to this file..." (you haven't searched, so you don't know)
- "The link checker in CI will catch anything I missed..." (then run it now, not after merging)
- "Anchors are minor, the page still loads..."
