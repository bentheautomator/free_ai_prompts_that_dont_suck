---
title: Check for Prior Art Before Choosing an Approach
slug: check-for-prior-art-before-choosing-an-approach
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "Inventing a third pagination pattern in a codebase that already has two"
---

# Check for Prior Art Before Choosing an Approach

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents committing to a from-scratch approach before checking whether the codebase already has one.

**[Copy-paste ready version](../../install/check-for-prior-art-before-choosing-an-approach.md)** — just the instruction block, no explanation.

## The Problem

Asked to add retry logic to an API client, the assistant designs retry logic: a backoff helper, jitter, a max-attempts wrapper. Decent code. Except `lib/http/retry.ts` already exists, is used by nine other clients, handles the auth-refresh case the new version doesn't, and is what the on-call engineer expects to find when this client misbehaves. The codebase now has two retry implementations, and the new one is the worse one.

This happens because generation is the assistant's native move. Given a problem, it produces a solution from the problem description — searching first is a detour from the generative flow, and nothing in the flow forces the detour. The cost compounds: every duplicated pattern is a divergence point. The two retry helpers drift; bugs get fixed in one; new code flips a coin on which to follow. Codebases don't rot from bad code as fast as they rot from five inconsistent versions of the same idea.

The check is fast. Before committing to an approach for any recognizable problem — retries, pagination, feature flags, validation, money handling, date math, queues — spend two minutes searching for how this codebase already does it. The answer changes the plan from "design X" to "use X" or, occasionally, to a documented "X exists but doesn't fit, because..."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check for Prior Art Before Choosing an Approach

ALWAYS search the codebase for an existing solution before designing one. For any recognizable problem class — retries, pagination, validation, flags, config, caching, date handling — assume prior art exists until a search says otherwise.

The core problem: generating a solution is the default move and searching is a detour, so codebases accumulate parallel implementations of the same idea that drift apart and confuse everyone who maintains them.

- Before committing to an approach, run the searches: the concept name, its synonyms, the library names that usually implement it. Check `lib/`, `utils/`, `common/`, and how a neighboring feature solved it.
- Read the closest existing analog. The feature most similar to yours encodes the house style for this problem; match it unless there's a stated reason not to.
- If prior art exists and fits: use it, even if you'd have designed it differently. Consistency beats marginal elegance.
- If it exists but doesn't fit: say so explicitly in the plan — "there's `retryWithBackoff`, but it can't express per-route policies because X" — so the divergence is a recorded decision, not an accident.
- If nothing exists, you've spent two minutes buying the right to invent.

**Red flags that you're about to violate this:**
- "This is a standard pattern, I'll just write it..."
- "Searching would take as long as writing it..." (it won't, and only one of them compounds)
- "My version will be cleaner than whatever's in there..."
- "I didn't see a helper in the files I happened to open..."
- "It's only a small utility, duplication is fine..."

---

## Why It Works

1. **It corrects the generation-first default with a mechanical step.** "Assume prior art exists" plus named search locations turns the check from a virtue into a procedure, which is the only form assistants reliably execute.

2. **It prices duplication correctly.** The visible cost of writing a second retry helper is twenty minutes; the real cost is two implementations drifting forever. Naming the compounding makes "my version is cleaner" the obviously bad trade it is.

3. **It legitimizes justified divergence.** Sometimes the existing pattern genuinely doesn't fit. Requiring a stated reason keeps that path open while ensuring it leaves a record the next reader can evaluate.

## Origin

A codebase audit found four feature-flag mechanisms: an env-var check, a database table, a config-file map, and a vendor SDK — each introduced by someone (human and assistant alike) solving "add a flag" without checking how flags were already done. A flag set in one system was overridden by a default in another, which took down a checkout experiment for two days. The consolidation project to get back to one mechanism took a full quarter; each original "just write it" had saved perhaps ten minutes.
