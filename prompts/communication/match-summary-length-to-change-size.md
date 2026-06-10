---
title: Match Summary Length to Change Size
slug: match-summary-length-to-change-size
category: communication
tags: [universal, reporting, clarity]
works_with: all
severity: medium
one_liner: "Ten paragraphs for a one-line fix, one breezy line for a rewrite"
---

# Match Summary Length to Change Size

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the inverse-proportionality problem: epic summaries for trivial fixes and one-liners for rewrites.

**[Copy-paste ready version](../../install/match-summary-length-to-change-size.md)** — just the instruction block, no explanation.

## The Problem

Change a single constant and the AI delivers a dissertation: the context of the change, the rationale, a restatement of the diff in prose, implications for future work, and a closing paragraph offering further assistance. Rewrite half a module and you might get "Refactored the session handling for better structure!" The length of the report and the weight of the change have come unstuck — sometimes perfectly inverted, because trivial changes are easy to narrate at length while big ones are hard to summarize at all. Writing ten paragraphs about a constant is effortless; compressing a rewrite into its three load-bearing facts is real work, and the model substitutes whichever output is easier to generate.

Both directions burn the reader. The padded report on the trivial change wastes minutes and — worse — trains the user to skim everything this assistant writes, so the one critical paragraph in next week's summary gets the same glaze-over as today's filler. The breezy line on the rewrite hides a review obligation: "refactored for better structure" gives the reader nothing to check and no signal that checking is warranted.

Verbosity here isn't a style preference; it's a signaling channel. Report length is one of the few cues a busy reader uses to decide how much attention a change deserves. When the channel carries noise, attention gets allocated wrong on every message.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match Summary Length to Change Size

ALWAYS scale your report to the weight of the change, not to what's easy to write. Trivial change, one line of summary. Major change, a real summary. Never the reverse.

The core problem: trivial changes are easy to narrate at length and big changes are hard to compress, so your output inverts the proportionality the reader relies on. They use length as a signal for how hard to look.

- One-line changes get one-line reports: "Fixed: timeout was 3s, now 30s, in `client.ts`." No context essay, no restated diff, no offer of further assistance
- Large changes get structured summaries: what changed at the behavior level, what to review most carefully, what to know before deploying. Length spent on substance, not narration
- Weight means impact, not line count — a one-line breaking change deserves a real report; see severity for content, this rule for proportion
- Never restate the diff in prose. The diff exists. Your summary's job is what the diff can't say: why, what it affects, what to watch
- Cut the ceremonial sections: no "Overview" for a typo fix, no "Next steps: let me know if you need anything!"
- Test before sending: does each paragraph change what the reader knows or does? Delete the ones that don't

**Red flags that you're about to violate this:**
- "A thorough write-up shows diligence, even for the constant change..."
- "The big refactor speaks for itself, a quick line will do..."
- "More explanation is always safer than less..."
- "I'll walk through the diff file by file so nothing is missed..."
- "This summary feels too short to be a real deliverable..."

---

## Why It Works

1. **It names the substitution.** The model isn't choosing verbosity; it's emitting whichever report is easiest to generate, which happens to invert proportionality. Stating the inversion as the failure makes the easy-output pull visible at the moment it operates.

2. **It reframes length as a signal channel, not a quality measure.** The model equates longer with more helpful. Recasting report length as information the reader uses to budget attention gives the model a reason to compress that aligns with its helpfulness objective instead of fighting it.

3. **The does-it-change-anything test is applied per paragraph, where padding lives.** Whole-message length rules get satisfied by uniform trimming. A per-paragraph utility test deletes the actual filler — the context essays and ceremonial closings — while leaving substantive length untouched.

## Origin

A reviewer received two messages from an assistant in one afternoon. The first, covering a one-character typo fix in an error string, ran eleven paragraphs including a section titled "Background." The second, covering a change that moved authentication from middleware into each handler, read in full: "Consolidated the auth logic — much cleaner now!" The reviewer, calibrated by message one to skim this assistant's prose, skimmed message two. One handler had been missed in the move; it shipped without auth, and was found by exactly the kind of person you'd hope wouldn't find it first.
