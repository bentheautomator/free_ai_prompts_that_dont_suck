---
title: Name the Tradeoffs of Your Approach
slug: name-the-tradeoffs-of-your-approach
category: communication
tags: [universal, reporting, risk]
works_with: all
severity: medium
one_liner: "Presenting a chosen approach without the costs that came bundled with it"
---

# Name the Tradeoffs of Your Approach

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents solutions from being presented as pure upside when every approach quietly bought something by selling something else.

**[Copy-paste ready version](../../install/name-the-tradeoffs-of-your-approach.md)** — just the instruction block, no explanation.

## The Problem

Every engineering choice purchases something by paying something: the cache buys speed and sells freshness, the denormalization buys read performance and sells write complexity, the polling loop buys simplicity and sells latency. AI assistants reliably present the purchase and pocket the receipt. "I added a caching layer, so the dashboard now loads instantly" — true, and silent about the part where the dashboard can now show five-minute-old numbers to someone reconciling accounts.

The model isn't hiding the tradeoff, exactly. It optimized for the stated goal (make it fast), achieved it, and reports the achievement. The cost side wasn't the assignment, so it doesn't make the summary — the same way a salesperson's pitch doesn't volunteer the maintenance schedule. And because the AI's solutions arrive looking finished and authoritative, the user rarely thinks to interrogate them the way they'd interrogate a colleague's proposal in design review.

The result is that tradeoffs get discovered instead of decided. The freshness sale, the write-amplification sale, the now-this-only-works-single-region sale — each one was made on the user's behalf, silently, and gets found later in the worst available way.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Name the Tradeoffs of Your Approach

NEVER present a solution as pure upside. Every approach bought its benefits by paying costs somewhere; name what was paid, in the same message that announces what was gained.

The core problem: you optimize for the stated goal and report the win, leaving the user to discover the bill later. A tradeoff disclosed is a decision; a tradeoff omitted is a trap.

- Pair every benefit claim with its cost: "Dashboard now loads instantly (cached). Cost: data can be up to 5 minutes stale, and the cache adds a process to deploy"
- Cover the standard ledgers: speed vs freshness, simplicity vs flexibility, memory vs compute, dev speed vs maintenance, works-now vs scales-later
- State who pays: "writes get slower" matters differently if writes are 1% or 60% of traffic — say which you believe and how you'd check
- If you considered alternatives, one line each on why they lost: "considered invalidation-on-write; rejected because the write paths are spread across three services"
- If the honest answer is "no meaningful downside," say what you checked before claiming it — that sentence is rare and should look expensive
- This is disclosure, not hedging: name the costs and still stand behind the choice if it's right

**Red flags that you're about to violate this:**
- "The downsides are minor enough that listing them undermines confidence..."
- "They asked for speed, so speed is the whole story..."
- "Staleness is implied by the word cache, surely..."
- "Mentioning rejected alternatives reopens a settled decision..."
- "I'll note the costs if the user asks how it works..."

---

## Why It Works

1. **The paired-claim format makes omission mechanical to spot.** A benefit sentence without a cost clause becomes a visibly incomplete pattern, so the model can lint its own summary. "Be balanced" can't be linted; "every gain names its price" can.

2. **The standard-ledgers list defeats the blank-stare problem.** Asked for tradeoffs in the abstract, a model often finds none — the solution looks clean from inside. A checklist of the five classic currencies gives it specific places to look, and one of them almost always pays out.

3. **The expensive no-downside clause inverts the easy exit.** Without it, "no real tradeoffs here" is the lowest-effort sentence available. Requiring evidence behind that claim makes honest disclosure cheaper than the dodge.

## Origin

An assistant moved a team's report generation into a background job queue to fix request timeouts — and presented it as strictly better: "requests return instantly, reports arrive by email." Unmentioned: results were no longer synchronous, so the partner-facing API that wrapped report generation now returned success before the report existed. A partner's integration, which read the response body, broke quietly. The fix was a day; the partner escalation was a week; the tradeoff would have been one sentence.
