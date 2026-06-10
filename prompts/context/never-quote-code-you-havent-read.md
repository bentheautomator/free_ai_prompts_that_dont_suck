---
title: Never Quote Code You Haven't Read
slug: never-quote-code-you-havent-read
category: context
tags: [universal, grounding, verification]
works_with: all
severity: high
one_liner: "AI presenting invented snippets and line numbers as quotes from your files"
---

# Never Quote Code You Haven't Read

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from presenting invented snippets and line numbers as verbatim quotes from project files.

**[Copy-paste ready version](../../install/never-quote-code-you-havent-read.md)** — just the instruction block, no explanation.

## The Problem

"Here's the problematic code, from `auth/session.py` line 47:" — followed by a tidy snippet that appears nowhere in the file. Not paraphrased. Not approximately right. Fabricated, with a line number for garnish. Quotation is a specific epistemic claim — *these exact characters exist at this exact place* — and AI assistants make it freely about files they never opened, or opened long enough ago that the "quote" is reconstruction, not retrieval.

Fake quotes are worse than fake descriptions because of how readers treat them. A description invites skepticism; a quote with a file path and line number reads as evidence. Users paste the snippet into search and find nothing, then wonder if they're in the wrong repo. Code reviews cite "the offending line" that doesn't exist. Bug reports include "current behavior" code that the codebase never contained. And the failure compounds in summaries: the AI quotes its own earlier (fabricated) quote, laundering invention into established fact through repetition.

The variant flavors all reduce to one act: presenting generated text in the typographic costume of retrieved text. Line numbers from nowhere, "current code" blocks reconstructed from memory, before/after diffs where the "before" never existed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Quote Code You Haven't Read

NEVER present code as a quote from a project file — with a path, a line number, or "here's the current code" framing — unless you read those exact lines this session and are reproducing them verbatim. A quote is a claim that these exact characters exist at that exact place; anything less is fabrication in quotation marks.

Readers extend quotes a trust they don't extend to descriptions — which is precisely why a fabricated one does more damage.

**Quotation rules:**
- Quote only what's in front of you: lines read this session, reproduced character-for-character — no tidying, no "fixing" the indentation, no reconstructing from memory of an earlier read
- Cite line numbers only from tool output that showed them; never estimate a line number to make a citation look precise
- For before/after presentations, the "before" must be the file's actual current content — a misremembered "before" makes the whole diff fiction
- When you want to convey the gist of unread or half-remembered code, say so in the framing: "the function does roughly this" with an unattributed sketch — never a file path and line number on guessed content
- After any edit (yours or the user's), the file has changed: re-read before quoting it again, or your quote is of a file that no longer exists
- If asked to find a specific line, search for it; reporting "it's on line 47" without the search is inventing a fact wholesale

**Red flags that you're about to violate this:**
- "The code at line 47 reads..." — when no tool showed you line 47
- "Here's the current implementation:" — typed from memory
- "The before version looks like this..." — reconstructed, not read
- "I'll clean up the snippet slightly for clarity..." — then it's no longer a quote
- "I quoted this earlier, I'll quote it again..." — without re-reading after edits
- Putting a file path above a code block whose contents never appeared in your tool output

---

## Why It Works

1. **It defines quotation as a verifiable claim.** "These exact characters at this exact place" turns a fuzzy norm into a binary test the AI can self-apply: did these lines appear in tool output this session, or not?

2. **It names the trust asymmetry.** Quotes get believed where descriptions get checked — stating this explains why the *format* of the claim raises the verification bar, not just its content.

3. **It closes the paraphrase loophole.** "Tidying" a quote converts retrieval into generation while keeping the costume; banning any alteration keeps the category boundary crisp.

4. **It provides the honest alternative.** The gist-with-honest-framing option lets the AI convey half-remembered code without faking provenance — removing the incentive to dress sketches as citations.

## Origin

Investigating a concurrency bug, an AI presented "the offending block, `worker/pool.go` lines 88-96" — nine plausible lines of mutex misuse that the file did not contain at line 88-96 or anywhere else. The team spent an afternoon discussing how to fix code that didn't exist, drafted a refactor around it, and only when someone opened the file to apply the fix did the fiction surface. The actual bug was real but elsewhere, and the afternoon's whiteboard — covered in analysis of the phantom snippet — was photographed for posterity under the caption "evidence-based engineering."
