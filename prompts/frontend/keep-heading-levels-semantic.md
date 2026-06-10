---
title: Keep Heading Levels Semantic
slug: keep-heading-levels-semantic
category: frontend
tags: [universal, frontend, accessibility]
works_with: all
severity: medium
one_liner: "Stops headings chosen for font size and styled divs where headings belong"
---

# Keep Heading Levels Semantic

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from picking heading tags by font size, skipping levels, stacking multiple h1s, or using styled divs where headings belong.

**[Copy-paste ready version](../../install/keep-heading-levels-semantic.md)** — just the instruction block, no explanation.

## The Problem

To an AI assistant matching a design mock, `<h4>` means "text about 16px and bold." So a page ends up with an `<h1>` hero, an `<h4>` section title (because the mock's section titles are smallish), an `<h2>` card label inside it (the mock's cards have prominent titles), and a `<div className="text-2xl font-bold">` for the most important heading on the page — because that one needed custom styling and divs don't fight back. The visual hierarchy is perfect. The document outline is gibberish.

That outline is not decorative. Screen reader users navigate by headings — jumping from heading to heading is *the* primary way they skim a page — and a skipped level or a misleveled heading tells them structure that doesn't exist: an h4 under an h1 implies two layers of missing content, a styled div is a section their heading navigation will never find. Multiple h1s make "what is this page about" ambiguous. Search engines read the same structure.

The deeper cause: the AI conflates two independent decisions — what level a heading is (an outline fact) and what it looks like (a CSS fact) — because HTML's default styling ties them together. Every misuse follows from resolving "the design wants it smaller" by changing the tag instead of the style.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It splits the conflated decision.** Every heading misuse is the AI answering a CSS question with an HTML answer; stating "level and look are independent" dissolves the entire failure class at its root.
2. **It covers both directions.** "Don't use headings for size" alone produces styled-div section titles; "don't use divs for headings" alone produces h-tags-as-big-text. The rule needs, and has, both edges.
3. **It addresses the component trap.** Hardcoded levels in reusable components are how outlines break without anyone choosing it; the `as`-prop pattern is the established fix the AI won't reach for unprompted.
4. **It ends with an outline read-through.** Listing the page's heading tags in order is a ten-second audit that makes a broken hierarchy as visible as a broken layout.

## Origin

A documentation site asked an assistant to "tighten up the visual hierarchy." It re-tagged headings to match the desired sizes: page titles stayed h1, but section titles became h4s (smaller look) and callout titles became h2s (bigger look). Sighted readers saw an improvement. A screen reader user reported that heading navigation had become "a random teleporter" — jumping by h2 landed on callout boxes while skipping every actual section. The fix re-leveled forty headings and moved all the size decisions into four CSS classes.
