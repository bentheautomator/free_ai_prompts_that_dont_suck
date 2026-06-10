---
title: Show Count and Sample Before Bulk Mutations
slug: show-count-and-sample-before-bulk-mutations
category: code-safety
tags: [universal, api, data]
works_with: all
severity: critical
one_liner: "AI bulk-deleting or bulk-updating records without showing what qualifies"
---

# Show Count and Sample Before Bulk Mutations

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running a bulk delete or update whose selection criteria nobody has actually seen the results of.

**[Copy-paste ready version](../../install/show-count-and-sample-before-bulk-mutations.md)** — just the instruction block, no explanation.

## The Problem

"Remove the inactive accounts" becomes a script: list accounts, filter where `last_login` is older than 90 days, call delete on each. The AI writes it, runs it, and reports success: 4,812 accounts removed. The user expected about 200. The filter also matched service accounts that never "log in," enterprise customers on SSO whose `last_login` field was never populated, and accounts created last week that hadn't logged in *yet*. The criteria were reasonable in English and wrong in data, and nobody looked at what they selected before the deletes flew.

This is the signature failure of bulk operations: the selection logic gets reviewed, the selection *results* never do. AI assistants go straight from "filter written" to "mutation executed" because the loop is right there and running it is one step. But criteria are hypotheses about data, and data is weirder than criteria. The count and a handful of concrete matched records would have exposed every one of those edge cases in ten seconds — 4,812 where you expected 200 is not a subtle signal.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Show Count and Sample Before Bulk Mutations

NEVER execute a bulk delete or bulk update without first reporting how many records match and showing a sample of them. Selection criteria are hypotheses about data; the matched set is the test, and you must look at the test results before mutating.

The core problem: filters that sound right in English match the wrong things in real data — null fields, service accounts, edge-case records — and once the loop runs, the damage is done at scale.

- Run the selection as a read-only query first. Report: total count, and 5-10 concrete matched records with identifying fields.
- Compare the count against expectation — yours and the user's. State your expectation *before* running the count. A large mismatch is a stop, not a footnote.
- Inspect the sample for impostors: nulls treated as "old," system/service records, recently created items, anything whose presence you can't explain from the criteria.
- Get explicit approval of the count and sample before any mutation runs. "Delete inactive accounts" is not approval for "delete these 4,812 specific accounts."
- Build in a cap: process a small bounded batch first (10-50), verify outcomes, then proceed. Never let the first execution be the full set.
- Make the run resumable and logged — write out each mutated ID — so a mid-run stop doesn't leave an unknowable half-state.

**Red flags that you're about to violate this:**
- "The filter is straightforward, no need to preview the matches..."
- "I'll run it and report how many it processed..."
- "Whatever matches, matches — that's what the criteria are for..."
- "Sampling first is a lot of ceremony for a cleanup task..."
- "The user said all inactive accounts, so the number doesn't matter..."

---

## Why It Works

1. **It tests the hypothesis before acting on it.** Framing criteria as hypotheses and the matched set as evidence converts "run the loop" into a two-phase scientific check the AI knows how to perform.

2. **It uses expectation mismatch as a tripwire.** Stating the expected count beforehand makes 4,812-vs-200 an unmissable contradiction rather than a number reported after the fact.

3. **It redefines what approval means.** "User approved the goal" silently becomes "user approved these specific records" — the rule blocks that substitution by requiring sign-off on the actual count and sample.

## Origin

An assistant was asked to purge "stale draft documents" via a CMS API. Its filter — drafts not modified in 60 days — also matched a set of approved templates that lived in draft status permanently by design. It deleted 1,940 documents; roughly 300 were the templates an entire department used daily. The API had no undelete. A count-and-sample step would have surfaced a template named "INVOICE MASTER - DO NOT DELETE" in the first ten records.
