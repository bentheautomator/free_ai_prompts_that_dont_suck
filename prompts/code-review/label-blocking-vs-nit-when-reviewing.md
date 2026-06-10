---
title: Label Comments Blocking or Nit When Reviewing
slug: label-blocking-vs-nit-when-reviewing
category: code-review
tags: [universal, review, communication]
works_with: all
severity: medium
one_liner: "Stops reviews where authors can't tell which comments actually gate merge"
---

# Label Comments Blocking or Nit When Reviewing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents posting a review where every comment carries the same implicit weight, leaving the author to guess which ones gate the merge.

**[Copy-paste ready version](../../install/label-blocking-vs-nit-when-reviewing.md)** — just the instruction block, no explanation.

## The Problem

An assistant reviews a PR and posts fourteen comments in one uniform voice: a possible data race, a naming suggestion, a missing test, a preference about import order, all delivered with identical confidence and identical formatting. The author now has to perform severity triage on someone else's feedback — and they'll get it wrong in one of two directions. Either they treat everything as blocking and spend a day appeasing import-order preferences, or they treat everything as optional and merge past the data race.

Models produce unlabeled comment streams because generation is local: each comment is written on its own merits, and nothing in the act of writing comment #9 asks "how does this rank against the other thirteen?" Severity grading is a pass over the whole review, and unless something demands that pass, it doesn't happen. The flat list also flatters the reviewer — fourteen comments looks thorough — while exporting the real work of prioritization to the person with the least information about what the reviewer meant.

An unlabeled review isn't neutral. It's a severity assignment done by the author, randomly.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Label Comments Blocking or Nit When Reviewing

When you review code, ALWAYS label every comment with its severity. The author must be able to compute "what do I have to do before this merges?" from your labels alone, without interpreting tone.

An unlabeled review delegates severity triage to the author — the person least equipped to know which of your concerns you'd block on.

- Use a small fixed vocabulary, prefixed on each comment: **blocking:** (would not merge without this), **suggestion:** (worth doing, your call), **nit:** (style or polish, feel free to ignore), **question:** (information request, not a change request).
- Decide the label by consequence: what happens if the author ignores this? Data corruption → blocking. Slightly worse name → nit. If you can't articulate the consequence, it's a question, not a comment.
- Match your verdict to your labels. Zero blocking comments → approve (with suggestions attached). Any blocking comment → request changes. Never "approve" with a comment you'd actually be upset to see ignored.
- Resist label inflation. If more than a few comments are blocking on routine code, re-examine whether you're labeling preferences as defects. Blocking is a claim you should be prepared to defend in the thread.
- End the review with a one-line tally: "1 blocking (the race in `flush`), 2 suggestions, the rest nits." That sentence is the author's entire work plan.

**Red flags that you're about to violate this:**

- "The severity is obvious from how I phrased each one..."
- "I'll let the author decide what's important to them..."
- "Marking it 'nit' makes it sound like I don't care about quality..."
- "Everything I flagged matters, so labels would all say blocking anyway..."
- "Labels feel bureaucratic for a small PR..."

---

## Why It Works

1. **The fixed vocabulary forces the global pass.** You can't prefix fourteen comments without ranking them against each other — the labeling requirement smuggles in the severity-triage step that local generation skips.
2. **"Decide by consequence" gives the label an algorithm.** The model asks "what breaks if ignored?" per comment, which both assigns the label and filters out comments that have no answer.
3. **Verdict-label consistency makes the review machine-checkable.** Blocking comments with an approval, or a changes-requested with only nits, are contradictions the model can detect in its own output before posting.
4. **The closing tally converts the review into a work plan.** The author's first question — "what gates merge?" — is answered in one line, so prioritization happens once, by the party who actually holds the priorities.

## Origin

An assistant's review of a schema-migration PR contained nineteen comments in flawless, uniform prose. Comment twelve noted that the new unique index would fail to build on the production table because of existing duplicate rows. The author, pattern-matching the review as "AI being thorough about style," batch-replied to the naming comments, ignored the rest, and merged. The deploy failed mid-migration exactly as comment twelve described, with the table locked. The comment had been right, polite, and indistinguishable from the eighteen that didn't matter.
