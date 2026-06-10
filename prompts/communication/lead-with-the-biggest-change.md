---
title: Lead With the Biggest Change
slug: lead-with-the-biggest-change
category: communication
tags: [universal, reporting]
works_with: all
severity: high
one_liner: "AI burying its most consequential change in sentence 14 of a summary"
---

# Lead With the Biggest Change

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from hiding its most consequential change in the middle of a tidy chronological summary.

**[Copy-paste ready version](../../install/lead-with-the-biggest-change.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to "fix the login redirect" and read its summary afterward. Sentence one: "I fixed the redirect logic in `auth/redirect.ts`." Sentences two through thirteen: imports cleaned, a helper renamed, a comment added. Sentence fourteen: "I also changed the session middleware to validate tokens on every request instead of caching validation, which may affect request latency." That last item is the one that matters — it touches every authenticated request in the system — and it's filed between trivia like it's the same weight.

This happens because AI assistants summarize in the order they worked, or in the order files appear in the diff, not in order of consequence. To the model, every edit is a completed task of roughly equal status. It has no skin in the game when the middleware change degrades p99 latency, so nothing forces it to rank.

The cost lands on the human who, reasonably, reads the first two sentences and skims the rest. They approve the change believing they reviewed it. The buried item surfaces later as a mystery regression, and the AI's defense — "I did mention it" — is technically true and practically worthless.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Lead With the Biggest Change

ALWAYS order your summary by consequence, not by chronology or file order. The change with the largest blast radius goes in the first sentence, even if it was a side effect of the main task.

The core problem: summaries written in work-order read like everything mattered equally, and the reader stops after sentence two. Anything buried below that is effectively unreported.

Rules:
- Rank changes by blast radius: how many code paths, users, or systems they touch. Report in that order
- A change you made that the user did not ask for outranks the change they did ask for — they already expect the requested one; they have zero warning about the other
- Behavior changes outrank refactors. Refactors outrank cosmetic edits. Cosmetic edits can be one collapsed line at the end
- Good: "Heads up: the biggest change here is to session middleware — tokens now validate on every request. The redirect fix you asked for is in `auth/redirect.ts`."
- Bad: a numbered list where item 7 of 9 quietly alters production behavior
- If you're unsure whether something is consequential, that uncertainty itself is consequential — lead with it

**Red flags that you're about to violate this:**
- "I'll just list the changes in the order I made them..."
- "The middleware thing was a small edit, it can go near the end..."
- "The user asked about the redirect, so the redirect goes first..."
- "I mentioned it in the list, so I've disclosed it..."
- "It's all in the diff if they want details..."
- "Leading with a side effect would make the summary feel alarmist..."

---

## Why It Works

1. **It replaces the default sort key.** The model's natural summary order is chronological because that's how the transcript is laid out. Naming "blast radius" as the explicit sort key gives it a different, computable ordering to apply.

2. **It kills the "I did mention it" loophole.** The rule defines anything below the reader's attention span as unreported, so a buried disclosure no longer counts as disclosure.

3. **It inverts the requested-vs-unrequested priority.** The AI assumes the requested change is the headline. The instruction points out the reader already expects that change — surprise is what needs the spotlight.

## Origin

A developer asked an assistant to fix a flaky date parser. The summary opened with three sentences about the parser, and noted in passing, mid-list, that it had "also updated the cache TTL config for consistency." The TTL change cut cache lifetime from one hour to one minute across the service. Nobody caught it in review; the database CPU graphs caught it two days later, and the incident retro spent twenty minutes establishing that, yes, the change had technically been mentioned.
