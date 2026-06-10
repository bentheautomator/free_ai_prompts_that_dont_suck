---
title: Comment the Why, Not the What
slug: comment-the-why-not-the-what
category: documentation
tags: [universal, docs, comments]
works_with: all
severity: medium
one_liner: "Comments that restate the code instead of explaining the reason behind it"
---

# Comment the Why, Not the What

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents comments that paraphrase the code in English while leaving the actual reasoning undocumented.

**[Copy-paste ready version](../../install/comment-the-why-not-the-what.md)** — just the instruction block, no explanation.

## The Problem

`// Increment the counter` above `counter++` is the canonical example, but AI assistants produce subtler versions constantly: `// Check if the user is an admin` above `if (user.isAdmin)`, `// Loop through the orders` above `for order in orders`. The comment is a translation, not an explanation. Anyone who can read the code learns nothing from it, and anyone who can't read the code shouldn't be trusting a paraphrase.

The damage is double. First, what-comments crowd out why-comments — the file looks documented, so nobody notices the actual decisions are unexplained. Second, what-comments rot instantly: change `isAdmin` to `hasRole('admin')` and the comment is now a small lie that someone has to notice and fix.

AI assistants default to this because restating code is cheap and looks diligent. Explaining *why* requires knowing the constraint, the bug being avoided, or the alternative that was rejected — and when the model doesn't know, it fills the space with narration instead of leaving it empty or asking. The valuable comment is `// Stripe retries webhooks for 72h, so this must be idempotent`. The worthless one is `// Handle the webhook`.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Comment the Why, Not the What

NEVER write a comment that restates what the adjacent code visibly does. A comment must add information the code cannot express: the reason, the constraint, the trap, or the rejected alternative.

The core problem: paraphrase comments add zero information, rot when the code changes, and make a file look documented while the real decisions go unexplained.

Do:
- Document non-obvious constraints: `# API caps page size at 100; do not raise this`
- Document why the obvious approach was rejected: `// Can't use Set here: order matters for the diff`
- Document external facts the code depends on: timeouts, vendor quirks, protocol rules, legal requirements
- Document intentional weirdness so nobody "fixes" it: `// Deliberately swallows the error; see retry loop below`

Don't:
- Translate code into English: `// Return the result` above `return result`
- Restate names: `// UserService handles users`
- Describe control flow the reader can see: `// If valid, save; otherwise throw`
- Pad code with comments to appear thorough

If you know no why, write no comment. An uncommented line is honest; a paraphrase is filler that someone must read, doubt, and maintain.

**Red flags that you're about to violate this:**
- "A brief comment here will make this easier to follow..."
- "I'll label each step of the function..."
- "This block looks bare without a comment..."
- "Describing what this does counts as documentation..."
- "I don't know why it's written this way, but I can at least say what it does..."
- "More comments will make this look well-documented..."

---

## Why It Works

1. **It defines comments by information added, not presence.** The model's default metric is "commented = documented." Redefining a valid comment as "something the code cannot say" makes paraphrases fail the test automatically.

2. **It legalizes silence.** Much of the noise comes from the model believing every nontrivial line deserves a comment. Explicitly stating that no-comment beats paraphrase removes the pressure to fill space.

3. **It names the rot mechanism.** What-comments are duplicate state: the logic exists in code and in prose, and only one gets updated. Framing them as a maintenance liability, not a courtesy, flips the cost calculation.

4. **It gives positive targets.** "Don't restate code" alone leaves a vacuum; the concrete categories (constraints, rejected alternatives, vendor quirks, intentional weirdness) tell the model what a good comment actually contains.

## Origin

A payments module had a deliberately duplicated lookup — the cache could not be used because invalidation lagged the ledger by up to a minute. The assistant that wrote it added twelve comments to the file, all of the `// Fetch the account` variety, and none explaining the duplication. A later cleanup pass (by another assistant) saw two identical lookups, helpfully deduplicated them through the cache, and the comments offered no resistance because none of them contained the one fact that mattered. The regression made it to staging before reconciliation tests caught stale balances.
