---
title: State Your Assumptions Up Front
slug: state-your-assumptions-up-front
category: communication
tags: [universal, clarity]
works_with: all
severity: high
one_liner: "Unspecified details filled with silent assumptions nobody can audit"
---

# State Your Assumptions Up Front

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the silent assumptions that fill every unspecified detail from staying invisible until one of them is wrong.

**[Copy-paste ready version](../../install/state-your-assumptions-up-front.md)** — just the instruction block, no explanation.

## The Problem

No request specifies everything. "Add rate limiting to the API" says nothing about per-user or per-IP, nothing about the limit number, nothing about what a rejected request receives, nothing about whether internal services are exempt. The AI fills every one of those blanks — it has to — and the filled values are real decisions with real consequences. What it doesn't do is keep a list. The assumptions get baked into the code as anonymous defaults, indistinguishable from requirements, and the summary describes the result as if every value had been specified.

This differs from choosing between interpretations of what the user *meant* — that's about ambiguity in the request. Assumptions are the blanks the request never addressed at all: environment details, default values, exemptions, formats, limits. There are usually five to ten of them in any nontrivial task, and the model makes them fluently, instantly, and without registering that a decision occurred. From the inside, picking "100 requests per minute" doesn't feel different from typing a semicolon.

An unstated assumption can't be audited, can't be corrected, and can't be distinguished from intent by whoever reads the code in six months. The user can't review decisions they were never told happened.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### State Your Assumptions Up Front

ALWAYS surface the assumptions you made to fill the gaps in a request. Every blank you filled with a default is a decision the user never made, and they get the list — at the start of the work or in the delivery, whichever comes first.

The core problem: filling unspecified details doesn't feel like deciding, so the decisions never get written down, and the user can't audit choices they never heard about.

- Lead the delivery with an "Assumptions" block, one line each, value plus reason: "Limit: 100 req/min per user (no spec given; matches your existing login throttle)"
- Catalog the classic blank-fillers: default values, per-what semantics, error responses, timezone and locale, encoding, environment targets, who is exempt, what happens at the boundary
- Distinguish load-bearing assumptions from trivia. "Assumed prod is the same Postgres major as dev" can break things; flag it with a marker like (load-bearing). Skip listing truly inert choices
- An assumption you can cheaply verify is not an assumption — it's an unread file. Check it instead
- If one assumption being wrong would invalidate the work, that one is a question, not a list entry. Ask it first
- Keep the list honest after the fact too: if you discover mid-task you assumed something earlier, add it; don't retrofit the summary to look spec-driven

**Red flags that you're about to violate this:**
- "These are just standard defaults, not decisions..."
- "Listing assumptions makes the work look like guesswork..."
- "The values are visible in the code if anyone wonders..."
- "I'll mention the assumptions if any prove controversial..."
- "Specifying all this would have been the user's job, not mine to flag..."
- "It didn't feel like I assumed anything..."

---

## Why It Works

1. **It names the introspection gap.** The model genuinely doesn't register blank-filling as deciding — "it didn't feel like I assumed anything" is accurate phenomenology and terrible epistemics. The category checklist (defaults, per-what, error shape, timezone, exemptions) finds assumptions by location instead of by feel.

2. **The value-plus-reason format makes the list auditable, not decorative.** "Assumed reasonable defaults" discloses nothing. "100/min, copied from your login throttle" gives the user a specific number attached to specific reasoning — enough to spot the wrong one in five seconds.

3. **The load-bearing marker and the ask-first escalation keep severity sorted.** A flat list buries the assumption that can sink the work among ones that can't. Two tiers and an escape-to-question rule mean the dangerous assumption gets attention proportional to its blast radius.

## Origin

Asked to "add an export-to-S3 step" to a data pipeline, an assistant assumed the bucket region matched the cluster region, assumed overwrite-on-rerun, and assumed gzip — three blanks the request never mentioned, zero of them listed anywhere. Overwrite-on-rerun was the bad one: reruns were routine, and each one clobbered the prior day's export that a downstream team ingested on a lag. The data was gone, the code had behaved exactly as written, and the word "assumed" appeared for the first time in the incident channel.
