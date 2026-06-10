---
title: Keep the Redundant Retries and Sleeps
slug: keep-the-redundant-retries-and-sleeps
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Keeps the sleeps and retries that quietly absorb real vendor quirks"
---

# Keep the Redundant Retries and Sleeps

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting retries, sleeps, and re-reads that look pointless but exist to absorb a real quirk in an external system.

**[Copy-paste ready version](../../install/keep-the-redundant-retries-and-sleeps.md)** — just the instruction block, no explanation.

## The Problem

Nothing triggers an AI assistant's cleanup reflex like a bare `sleep(2)` after an API call, a retry loop around an operation that "can't fail," or code that reads a record back immediately after writing it. These look like superstition — and the assistant has been trained that sleeps are flaky-test smell, retries belong in middleware, and read-after-write is wasted I/O. Out they go, usually as an unremarked line in a larger refactor.

But defensive timing code in legacy integrations is almost never superstition. It's a measurement. The sleep exists because the vendor's API returns success before the resource is actually queryable. The retry exists because the payment gateway throws a transient error on roughly one call in five hundred. The read-back exists because the upstream system is eventually consistent and someone got burned. Each one was added by an engineer staring at a production failure, and each one works precisely by being invisible: it converts a vendor quirk into a non-event, forever, until someone deletes it and the quirk returns from the dead with no context attached.

The deleted version passes every test, because the quirk lives in the vendor's infrastructure, not in any environment the test suite touches. The failure rate comes back at production scale, intermittently — the most expensive kind of bug to rediscover.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep the Redundant Retries and Sleeps

NEVER delete a retry, sleep, delay, re-read, or double-check around an external interaction because it looks unnecessary. In legacy code these are absorbers: each one neutralizes a real quirk in a vendor API, a consistency model, or a race that someone diagnosed in production. They look pointless *because they are working*.

Before removing or "simplifying" any defensive timing code:

- `git blame` it. Defensive code added in a small, standalone commit — especially with words like "intermittent," "flaky," "vendor," or a ticket number — is a documented incident response. It stays.
- Identify what it touches. A sleep before a vendor poll, a retry around a third-party call, a read-back after a write to an eventually-consistent store: the proximity to an external boundary is the tell that it absorbs that boundary's behavior.
- Don't be fooled by passing tests. The quirk these constructs absorb lives in production infrastructure you cannot reproduce locally; green CI is evidence of nothing here.
- If the construct is genuinely problematic (blocking a hot path, masking errors), propose a like-for-like replacement that preserves the absorption — backoff instead of fixed sleep, bounded retry with logging — and say what quirk you believe it handles.
- If you can't determine what it absorbs, leave it and flag it. "Unexplained defensive code at a vendor boundary" defaults to load-bearing.

**Red flags that you're about to violate this:**
- "This sleep is obviously a hack someone forgot to remove."
- "The client library already retries, this loop is redundant."
- "Reading the row back right after writing it is pointless."
- "This API is reliable, the error handling here is paranoid."
- "All tests pass without the delay, so it wasn't doing anything."
- "I'll drop these while I'm restructuring the function."

---

## Why It Works

1. **"They look pointless because they are working" resolves the core illusion.** A successful absorber produces no visible failures, which the AI reads as evidence of uselessness; naming the inversion flips the inference.
2. **Boundary proximity is a mechanical detector.** "Is this within arm's reach of a vendor call or an eventually-consistent store?" is checkable from the code alone and catches the dangerous cases without protecting every sleep everywhere.
3. **It pre-debunks the green-CI argument,** which is the rationalization that actually ships these deletions: the quirk is in infrastructure the tests never touch, so passing tests are explicitly defined as non-evidence.
4. **Like-for-like replacement keeps improvement possible.** The rule doesn't enshrine `sleep(2)` forever; it requires the replacement to do the same absorbing, which forces the AI to first understand what's being absorbed.

## Origin

An integration with a document-signing vendor contained a retry-once wrapper and a 1.5-second delay between creating an envelope and sending it, both uncommented. A refactor removed them as obvious cruft; the code was cleaner and every test passed. In production, roughly 2% of envelopes began failing to send — the vendor's create call returned success up to two seconds before the envelope was actually usable, a behavior confirmed in a years-old support thread the original engineer had linked in the commit message. The delay went back in, this time with the support thread URL in a comment, where the next refactorer might actually see it.
