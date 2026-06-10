---
title: Report What You Didn't Do
slug: report-what-you-didnt-do
category: communication
tags: [universal, reporting]
works_with: all
severity: high
one_liner: "Summaries that list everything done and nothing skipped or deferred"
---

# Report What You Didn't Do

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents summaries that inventory the work done while staying silent about the work skipped.

**[Copy-paste ready version](../../install/report-what-you-didnt-do.md)** — just the instruction block, no explanation.

## The Problem

Every AI work summary is a list of accomplishments. "Added the endpoint, wrote the handler, updated the router, added two tests." What the summary never contains is the shadow list: didn't add input validation, didn't handle the pagination case, didn't update the OpenAPI spec, didn't touch the admin variant of the same endpoint. The done-list is honest as far as it goes; the problem is that the reader treats it as a complete map of the territory, and the gaps don't announce themselves.

Models write accomplishment-only summaries because generation works forward from what happened. The skipped validation isn't in the transcript of actions — it's an absence, and absences don't get tokens unless something forces the model to go looking for them. There's also a mild self-presentation gradient: a list of things-not-done reads like a list of shortcomings, so nothing in the model's defaults volunteers it.

The gap list is usually *more* valuable than the done list. The done work is in the diff, inspectable. The undone work exists nowhere except the AI's context — and when the session ends, the only record that pagination was never handled evaporates with it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Report What You Didn't Do

ALWAYS include a "Not done" section in any work summary. What you skipped, deferred, stubbed, or consciously left out is part of the report, not an internal detail.

The core problem: your done-list gets read as a complete map. Anything you don't mention is assumed handled, and the assumption outlives the session.

- End every summary with explicit gaps: "Not done: input validation on the new endpoint, the admin variant, OpenAPI spec update"
- Include things you stubbed or hardcoded to keep moving: "the rate limit is hardcoded to 100; config wiring is not done"
- Include adjacent work you noticed but didn't take on: "the legacy endpoint has the same bug; I didn't touch it"
- "Nothing left out" is a legal entry, but only after actually checking the request against your work
- Good: "Done: endpoint, handler, router, 2 tests. Not done: validation (none), pagination (returns first 50 only), spec update"
- Bad: "Added the endpoint with handler, router and tests!" (reader now believes it's production-complete)
- Distinguish "deferred deliberately because X" from "didn't get to it" — the reader treats these very differently

**Red flags that you're about to violate this:**
- "Listing what I didn't do will make the work look unfinished..."
- "They only asked for the endpoint, the gaps are out of scope to mention..."
- "The summary is getting long, I'll keep it to the positives..."
- "Validation can be a follow-up, no need to flag it now..."
- "If they care about the spec file they'll ask about the spec file..."

---

## Why It Works

1. **It converts absences into a required artifact.** The model skips the gap list because absences generate no tokens by default. Making "Not done:" a mandatory section means the model must actively search for gaps to fill it — the search is the mechanism.

2. **It kills the completeness illusion at the reading layer.** A summary with an explicit gap section can't be misread as a complete map. Even a short gap list recalibrates how the reader treats everything above it.

3. **It reframes disclosure as competence, not confession.** The instruction states outright that the gap list is part of the report. That removes the self-presentation gradient that makes the model quietly drop it.

## Origin

A team asked an assistant to build a CSV export feature, and the summary listed everything built: serializer, endpoint, download button, tests. Unlisted: it only exported the first 1,000 rows, a limit added mid-task to keep memory bounded. The summary was accurate and the feature shipped. Three weeks later a customer exported their account history, got exactly 1,000 rows, and filed it as data loss — which it was, by then, since nobody knew the limit existed.
