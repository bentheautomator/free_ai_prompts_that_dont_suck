---
title: Commit to a Recommendation
slug: commit-to-a-recommendation
category: communication
tags: [universal, clarity, calibration]
works_with: all
severity: medium
one_liner: "Both-sides pros-and-cons mush when the user asked which one to pick"
---

# Commit to a Recommendation

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the balanced-considerations dodge when the user explicitly asked the AI to pick one.

**[Copy-paste ready version](../../install/commit-to-a-recommendation.md)** — just the instruction block, no explanation.

## The Problem

"Should we use WebSockets or polling for this?" is a request for a verdict. What comes back is a symmetrical brochure: WebSockets offer lower latency but add connection management complexity; polling is simpler but generates more requests; the choice depends on your specific requirements. Every sentence true, every sentence useless — the user knew the brochure before they asked. What they wanted was the thing the AI withheld: a pick, with reasons, from something that has read their codebase and seen a thousand systems like theirs.

Models dodge verdicts because a recommendation can be wrong and a survey can't. Balance reads as wisdom; commitment risks correction. So the model spreads its probability mass across both options and ships the spread — which is precisely the one output the question excluded. "It depends on your requirements" delivered to someone who just described their requirements is the survey's purest form.

The dodge also has a compounding cost: decision-fatigue transfer. The user delegated the decision because they wanted it off their plate. The brochure hands it back, now padded with considerations they must weigh themselves — the AI did the reading and skipped the thinking.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Commit to a Recommendation

When asked to choose, ALWAYS choose. "Which should we use?" is answered by a pick, stated first, with reasons — not by a balanced survey of considerations.

The core problem: a recommendation can be wrong and a survey can't, so you ship the survey. But the user asked precisely because they wanted the decision off their plate, and the survey hands it back heavier.

- First sentence is the verdict: "Polling. Your update frequency is every 30s and you already run behind a proxy that complicates WebSocket connections"
- Reasons must be specific to their situation, not generic attributes of the options. If you know nothing about their situation, say what single fact would decide it and ask for that
- State the conditions that would flip your pick: "I'd flip to WebSockets if you need sub-second updates or plan presence features" — this is the honest residue of "it depends", compressed into one usable line
- Confidence is allowed to be moderate; the pick still gets made: "Weakly held, but: polling." A weak verdict beats a strong shrug
- If the options are genuinely equivalent for their case, say THAT as the verdict: "Either works here; flip a coin or pick the one your team knows. Equivalent because X." Equivalence is a finding, not a dodge
- Keep the brochure if it's useful, but below the verdict, never instead of it

**Red flags that you're about to violate this:**
- "Presenting both sides respects their autonomy to decide..."
- "I don't know every detail of their context, so I shouldn't commit..."
- "If my pick turns out wrong, I'll have misled them..."
- "'It depends' is technically the most accurate answer..."
- "A structured comparison table is more professional than an opinion..."
- "They can weigh the tradeoffs themselves, my job is to lay them out..."

---

## Why It Works

1. **Verdict-first placement makes the dodge structurally impossible.** A survey with a verdict requirement bolted on ends with "...so it depends." Requiring the pick as the opening sentence means the model must form one before generating anything — the commitment happens before the hedging machinery spins up.

2. **The flip-conditions line converts hedging into information.** The model's urge to say "it depends" contains something real: the dependency. Forcing it into the form "X would change my answer" extracts the value and discards the evasion.

3. **Legalizing the equivalence verdict closes the last exit.** Sometimes options genuinely tie — and without an approved way to say so, "they're equivalent" becomes the universal escape hatch. Requiring equivalence to be argued ("equivalent because X") makes it a claim that costs something, so it only gets used when true.

## Origin

A two-person startup asked an assistant whether to build their job queue on the database they already ran or adopt a dedicated message broker. They got nine hundred words of even-handed comparison and the closing sentence "ultimately, the right choice depends on your scaling needs and operational preferences." They had described both in the question. The founders spent a week of evenings relitigating the brochure, picked the broker, and spent a month operating infrastructure they didn't need — for a queue that, at their scale, the verdict-shaped answer ("your database; revisit at 100x volume") would have settled in one line.
