---
title: Match the Existing Docs Voice and Structure
slug: match-the-existing-docs-voice-and-structure
category: documentation
tags: [universal, docs]
works_with: all
severity: medium
one_liner: "New doc pages written in a foreign voice and format that fragment the docs"
---

# Match the Existing Docs Voice and Structure

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from dropping a foreign-voiced, differently-structured doc page into a documentation set that had a consistent style until five minutes ago.

**[Copy-paste ready version](../../install/match-the-existing-docs-voice-and-structure.md)** — just the instruction block, no explanation.

## The Problem

The project's docs are terse and imperative: short sections, second person, code block per step, no emoji. The AI's new page arrives with a "🚀 Overview" section, three paragraphs of marketing-adjacent throat-clearing ("In today's fast-paced development landscape..."), a "Why This Matters" section nobody else's pages have, and headings in Title Case where the rest of the docs use sentence case. The content might even be good. It still reads like a guest post.

Models default to their house style — enthusiastic, sectioned, emoji-bulleted — because that's the mean of their training data, and nothing in "write a doc page for the rate limiter" says otherwise. But documentation sets derive much of their usability from uniformity: readers learn where to look (parameters always in a table, examples always last), and every page that breaks the pattern resets that learning. Style drift also compounds: the next writer matches whichever page they saw last, and after a few AI contributions the docs read like an anthology.

Inconsistent docs don't just look unprofessional. They make readers re-derive each page's structure from scratch, which is a tax on every future visit.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match the Existing Docs Voice and Structure

ALWAYS read at least two existing doc pages before writing a new one, and match what you find: voice, structure, heading style, and formatting conventions. New pages should be indistinguishable from the natives.

The problem: your default writing style is nobody's house style. A doc set's value depends on uniformity, and one foreign page starts the drift that ends in an anthology.

Rules:
- Before writing, open the most recently updated comparable pages (a how-to if you're writing a how-to, a reference if a reference) and extract the pattern: section order, heading case, person and tense, code block conventions, admonition usage
- Match the section skeleton. If existing pages go Synopsis, Usage, Options, Examples, yours does too, in that order, even if you'd structure it differently
- Match tone calibration: if the docs are terse, be terse. Do not add an introduction explaining why the topic matters unless existing pages have one
- Suppress your defaults unless the docs use them: no emoji, no "Let's dive in", no bold-lead bullet lists, no concluding summary section
- Check for a style guide (`STYLE.md`, `docs/contributing`, vale/markdownlint configs) and treat it as binding
- If the existing docs are internally inconsistent, match the newest pages or the section you're joining, and say which convention you followed
- Improving the house style is a proposal to make to the user, not a decision to embody in one divergent page

**Red flags that you're about to violate this:**
- "My structure for this page is clearer..."
- "A friendly intro makes it more approachable..."
- "I'll write it my way; style is cosmetic..."
- "The existing docs are too terse, I'll be more thorough..."
- "Emoji headers make it scannable..."
- "I didn't check the other pages, but this format is standard..."

---

## Why It Works

1. **It replaces the model's prior with the repo's.** Without explicit input, the model writes the average doc page on the internet. Forcing a read of two local pages swaps that prior for the actual house pattern.

2. **Uniformity is a reader-side feature, not an aesthetic.** Consistent structure lets readers navigate by habit (options are always in the table). The rule protects the navigation contract, not the typography.

3. **It blocks one-page reform.** The temptation to demonstrate a better style inside a single page guarantees inconsistency whichever style is better. Routing improvements through the user keeps the set uniform either way.

4. **The tie-breaking clause handles messy reality.** Most doc sets are already a little inconsistent; "match the newest comparable page and say so" keeps the rule decidable instead of abandonable.

## Origin

A CLI project with spartan, man-page-style docs merged several AI-written pages over a quarter. Each was individually fine and collectively chaos: three heading conventions, two tones, and one page with a FAQ section that answered questions no other page acknowledged. A user filed an issue asking whether the docs were maintained by the same project. The cleanup commit that restored one voice touched every AI-authored page and nothing else.
