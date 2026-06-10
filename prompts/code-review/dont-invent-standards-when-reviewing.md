---
title: Don't Invent Standards When Reviewing
slug: dont-invent-standards-when-reviewing
category: code-review
tags: [universal, review]
works_with: all
severity: medium
one_liner: "Stops review comments citing conventions the project never actually adopted"
---

# Don't Invent Standards When Reviewing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents flagging code as violating "the project convention" or "best practice" without verifying that any such rule exists where this code lives.

**[Copy-paste ready version](../../install/dont-invent-standards-when-reviewing.md)** — just the instruction block, no explanation.

## The Problem

The review comment reads: "This violates the project's convention of returning Result types from service methods." Confident, specific, authoritative. Also fabricated: the project has no such convention — half the service methods throw, the style guide is silent, and the "convention" is a pattern the model absorbed from other codebases entirely. The author, who can't be sure they haven't missed a rule, either complies (creating an inconsistency with the rest of the codebase in the name of consistency) or spends an hour searching for a document that doesn't exist.

Models invent standards because their training is a compost heap of thousands of codebases' norms, and review-comment language pattern-matches toward citing authority — "per convention," "as is standard," "the established pattern here." Generating the citation is free; verifying it requires actually checking the repo's style docs, lint config, and prevailing practice, which nothing forces. The result is feedback with the *form* of institutional knowledge and the content of a guess.

It's uniquely corrosive because authority claims short-circuit debate. An opinion invites discussion; "this violates our convention" invites compliance. When the invented rule is eventually discovered to be invented, every past comment from that reviewer gets retroactively reclassified as "possibly made up."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Invent Standards When Reviewing

NEVER cite a project convention, team standard, or "established pattern" in a review comment unless you have verified it exists in this repository. Unverified appeals to authority are fabrications with a confident accent.

You have absorbed the norms of a thousand codebases. This project follows at most one of them, and you don't know which until you look.

- Before writing "the convention here is X," check: the style guide or CONTRIBUTING doc, the lint/formatter config, and what the surrounding code actually does. If the codebase predominantly does X, cite the evidence: "the other 9 service modules return Result (see `billing.rs`, `users.rs`) — this one throws."
- If the practice you want to recommend isn't established in this repo, present it as what it is — your recommendation, with its reasoning: "Consider returning Result here: callers already match on it in the two call sites, and it makes the timeout case explicit." That comment stands on its merits instead of a forged signature.
- "Best practice" claims get the same treatment: name the concrete benefit in this code, or drop the phrase. If the only argument is that the practice is widely admired, it's a preference.
- Never cite a style guide section, doc, or prior decision you haven't opened in this session. If you remember a rule but can't find it, say "I believe there's a convention about this, but I couldn't locate it — can someone confirm?"
- When the repo is genuinely inconsistent (half throws, half returns Result), say *that* — inconsistency is a real finding. Picking one side and calling it the convention is not.

**Red flags that you're about to violate this:**

- "Most codebases I've seen do it this way, so this team probably does too..."
- "Citing a convention will land better than stating my preference..."
- "It's standard practice, I don't need to check whether it's standard here..."
- "There's surely a style guide somewhere that says this..."
- "The pattern feels canonical for this framework..."

---

## Why It Works

1. **It forces the citation to have a referent.** A rule that must point at a file, a config line, or counted instances in the repo can't be assembled from training-data vibes — the check either produces evidence or kills the comment.
2. **It preserves the recommendation channel.** The model isn't told to suppress good ideas, only to stop laundering them as institutional rules. Honest-preference comments still ship, and they invite the discussion authority claims suppress.
3. **Evidence-cited conventions are falsifiable in seconds.** "9 of 10 modules do X, see these files" lets the author verify instantly — which builds exactly the trust that fabricated citations spend.
4. **The inconsistency carve-out handles the messy real case.** Most repos are mixed; giving the model a truthful thing to say about mixed evidence removes the temptation to round it up to a unanimous rule.

## Origin

An assistant reviewer told a new contributor their PR "violates the repository's requirement that all public functions have docstring examples," requesting changes. The contributor spent an evening writing forty doctest examples — several of which made fragile assertions about formatting — then asked in the team channel where the requirement was documented. It wasn't. Nothing in the repo had ever required it; coverage was about 20%. The doctests broke in the next minor release of a dependency, and the contributor's second PR went to a different project.
