---
title: Fix Doc Links When You Move Files
slug: fix-doc-links-when-you-move-files
category: documentation
tags: [universal, docs]
works_with: all
severity: medium
one_liner: "Moving or renaming files while every link pointing at them goes dead"
---

# Fix Doc Links When You Move Files

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from moving or renaming files while leaving every link that pointed at the old location quietly broken.

**[Copy-paste ready version](../../install/fix-doc-links-when-you-move-files.md)** — just the instruction block, no explanation.

## The Problem

The AI reorganizes the docs folder — `docs/setup.md` becomes `docs/getting-started/installation.md`, very tidy — and considers the job done when the files are in their new homes. It never asks who was pointing at the old homes. The README's "see the [setup guide](docs/setup.md)" now 404s. So does the link in `CONTRIBUTING.md`, the one in the issue template, the one in a code comment that says "configuration documented in docs/setup.md", and the anchor link `#environment-variables` that survived the move but lost its heading.

Code refactoring tools update imports when you move a module; nothing updates Markdown links when you move a doc. The references live in prose, comments, templates, and config strings, none of which any compiler checks. The AI's move operation succeeds, the tree looks clean, and the link rot is invisible until a reader clicks.

Dead internal links are small individually and corrosive collectively: each one teaches readers that the docs can't be trusted to navigate, so they stop following links and start grepping, which defeats the purpose of having structured docs at all.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It redefines the move as a graph operation.** A file is a node with inbound edges. Framing completion as "no dangling edges" makes the reference search part of the move instead of an afterthought.

2. **The old path is a perfect search key.** Unlike most doc-staleness, broken links are mechanically findable: the exact string that's now wrong is known at move time. The rule spends that knowledge immediately.

3. **It enumerates the non-obvious reference homes.** Models check Markdown files and stop. Navs, templates, comments, and badges are where the survivors hide; listing them converts blind spots into checklist items.

4. **It separates anchor breakage from link breakage.** Anchor rot passes every file-level check while still dumping readers at the top of the wrong page. Naming it gets it checked at the only moment anyone is looking.

## Origin

A docs restructure moved twenty files into topic folders. The PR was reviewed for content and structure, both fine. Over the following month, support noticed users repeatedly asking questions that the docs answered, because the top three Google results for the product's setup deep-linked to old paths that now returned 404 with no redirect. Traffic to the setup guide dropped by more than half until redirects were added, one stale inbound link at a time.
