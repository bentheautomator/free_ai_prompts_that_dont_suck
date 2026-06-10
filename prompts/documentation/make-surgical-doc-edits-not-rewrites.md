---
title: Make Surgical Doc Edits, Not Rewrites
slug: make-surgical-doc-edits-not-rewrites
category: documentation
tags: [universal, docs]
works_with: all
severity: medium
one_liner: "Rewriting a whole doc to fix one sentence, losing curated content"
---

# Make Surgical Doc Edits, Not Rewrites

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from rewriting an entire document when asked to change one part of it, silently dropping hard-won content in the process.

**[Copy-paste ready version](../../install/make-surgical-doc-edits-not-rewrites.md)** — just the instruction block, no explanation.

## The Problem

"Update the README's install section for the new package name." The AI regenerates the entire README. The install section is correct now — and the troubleshooting entry about the M1 linker bug is gone, the carefully-worded security disclosure paragraph that legal approved is paraphrased, the maintainer's deliberate ordering of examples (simple before exotic) is reshuffled, and the weird-looking but intentional code fence with the locale workaround got "cleaned up." The diff is 200 lines for a 4-line request, which means the reviewer either reads an essay or rubber-stamps the losses.

Models do this because regenerating a whole document is *easier* for them than editing inside one: producing fluent full-document output is the native operation, while surgical patching requires holding everything else fixed. The rewrite also flatters the model's style preferences, so the doc drifts toward generic-AI voice with every pass. Prose has no test suite; nothing fails when the M1 workaround disappears, until the next M1 user does.

Documentation accumulates value in exactly the parts that look odd: the awkward sentence that survived three rounds of legal, the troubleshooting entry from a 2am incident. Wholesale rewrites strip-mine that history because the model can't tell curation from clutter.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Make Surgical Doc Edits, Not Rewrites

NEVER rewrite a whole document when the request was to change part of it. Edit the lines the task requires and leave every other line byte-identical.

The problem: full regeneration silently drops curated content — incident-driven troubleshooting notes, legally vetted wording, deliberate ordering — and buries a four-line change in a 200-line diff nobody can review.

Rules:
- Scope the edit to the sections the request names. "Update the install section" authorizes changes to the install section, full stop
- Untouched sections must survive byte-for-byte: same wording, same order, same formatting, same oddities. Odd-looking prose in mature docs is usually load-bearing
- Resist incidental improvement: do not fix tone, restructure headings, or modernize phrasing in sections you pass through. If you see real problems elsewhere, list them in your reply as suggestions
- Keep the diff proportional to the request. A one-sentence change producing a one-screen diff is a signal you've rewritten, not edited
- If the requested change genuinely requires restructuring beyond its section (the section is duplicated, or the fix contradicts another part), say so and propose the wider edit before making it
- When a full rewrite is actually wanted, the user will use words like "rewrite", "redo", or "restructure". Absent those words, assume surgical

**Red flags that you're about to violate this:**
- "While I'm in this file, I'll polish the rest..."
- "Regenerating the whole doc is cleaner than patching it..."
- "This section reads badly; the user will appreciate the improvement..."
- "I'll restructure it the way docs like this are usually organized..."
- "The old wording was awkward..." (awkward and approved, possibly)
- "The diff is large but it's all improvements..."

---

## Why It Works

1. **Byte-identity is enforceable; "preserve the spirit" is not.** A model told to keep untouched sections exactly as-is can verify its own compliance against the source. A model told to "keep the content" will paraphrase, and paraphrase is where vetted wording dies.

2. **Diff size is a self-check the model can run.** Comparing diff magnitude to request magnitude catches the rewrite before it ships, using a signal (line count) that's available without any external tooling.

3. **It protects Chesterton's prose.** The rule encodes that odd-looking content in mature docs correlates with hidden constraints — legal review, past incidents, downstream parsers — that the model cannot see and therefore cannot safely "improve."

4. **It preserves reviewability.** Reviewers approve what they can read. A proportional diff gets actually reviewed; a full-file rewrite gets skimmed and approved, which converts every silent loss into a merged loss.

## Origin

A maintainer asked an assistant to update one version number in a project's security policy doc. The assistant returned a fully rewritten policy: friendlier, better organized, and missing the specific 90-day disclosure-window sentence that had taken three weeks of negotiation with the company's counsel to approve. The change merged because the diff was too large to read carefully on a Friday. The deletion surfaced two months later when a researcher cited the old policy from an archive, and the wording had to go back through legal from scratch.
