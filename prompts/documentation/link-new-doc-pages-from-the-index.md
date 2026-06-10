---
title: Link New Doc Pages From the Index
slug: link-new-doc-pages-from-the-index
category: documentation
tags: [universal, docs]
works_with: all
severity: medium
one_liner: "New doc pages created but never linked, invisible to every reader"
---

# Link New Doc Pages From the Index

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from creating doc pages that nothing links to, making them invisible to every reader navigating the docs normally.

**[Copy-paste ready version](../../install/link-new-doc-pages-from-the-index.md)** — just the instruction block, no explanation.

## The Problem

The user asks for documentation on the new webhooks feature, and the AI writes a genuinely good page at `docs/webhooks.md`. Then it stops. The docs index doesn't mention it. The mkdocs nav doesn't include it, so the site build either skips the page or dumps a warning nobody reads. The README's documentation section lists six topics, and webhooks isn't one of them. The page exists in the same way a book exists in a library with no catalog entry: physically present, functionally absent.

Readers don't find docs by listing directories; they find them by following links from where they already are — the index, the sidebar, the related page that says "see also." A page with no inbound links has no readers, which means it also has no error reports, which means it quietly rots without even the feedback loop that normally keeps popular pages honest. Months later someone asks "do we have webhook docs?" and someone else writes a second page, and now there are two.

The AI stops at file creation because the file was the deliverable it could see. The navigation graph — index pages, nav configs, see-also links — is a separate structure it was never asked about, so it never touches it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It treats publication as a graph property, not a file property.** Pages acquire readers exclusively through inbound edges. Making "wired into the nav" the definition of done targets the property that actually delivers readers.

2. **It exploits the build's orphan detection where it exists.** Most doc generators already detect unrouted pages; the rule turns a routinely-ignored warning into the acceptance check for the task.

3. **Contextual links serve readers at the moment of need.** Index links serve browsers; see-also links serve people mid-problem on a related page, which is where most documentation demand actually occurs.

4. **It prevents duplicate-page genesis.** The second webhook doc gets written because nobody could find the first. Discoverability now is the cheapest possible prevention of divergence later.

## Origin

An audit of a product's docs site found nine pages, several of them excellent, that were unreachable from any navigation: written over a year by various contributors and assistants, committed, and never added to the nav config. Two topics had been documented twice because the first page was undiscoverable, and the pairs disagreed. Support had been answering questions covered by the orphaned pages the whole time. The fix took twenty minutes; the audit that found the problem took two days.
