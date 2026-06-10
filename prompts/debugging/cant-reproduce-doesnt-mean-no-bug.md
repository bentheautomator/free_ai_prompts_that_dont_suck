---
title: Can't Reproduce Doesn't Mean No Bug
slug: cant-reproduce-doesnt-mean-no-bug
category: debugging
tags: [universal, debugging]
works_with: all
severity: high
one_liner: "AI dismissing real bug reports because the failure won't happen locally"
---

# Can't Reproduce Doesn't Mean No Bug

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from concluding "works as expected" when a reported failure declines to appear in the AI's own environment.

**[Copy-paste ready version](../../install/cant-reproduce-doesnt-mean-no-bug.md)** — just the instruction block, no explanation.

## The Problem

The report says uploads fail. The AI runs an upload locally, it succeeds, and the verdict comes back: "I tested this and it works correctly — the issue may have been transient." Translation: the bug didn't perform on command in one environment, so the user's experience has been overruled. The report wasn't wrong; the reproduction attempt was incomplete. The failure needs production data volumes, or Safari, or a non-ASCII filename, or a slow connection, or the timezone the user is actually in, or an account in a state the AI's test account isn't in.

A failed reproduction attempt is not evidence of absence — it's a measurement of the *difference* between the reporting environment and the testing one. That difference is the most valuable lead in the whole investigation: enumerate what differs (data, browser, OS, locale, account state, config, scale, network, time), and the bug's trigger is on the list. The AI instead treats its own environment as the arbiter of reality, because "I ran it and it worked" is a satisfying, checkable fact, while "what's different about their setup?" opens a tedious investigation.

Dismissed-as-unreproducible bugs have a particular cost profile: they return, repeatedly, accumulating "cannot reproduce" stamps while real users keep hitting them, until someone finally asks the difference question that should have been step two.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Can't Reproduce Doesn't Mean No Bug

NEVER conclude a reported bug doesn't exist because it didn't reproduce in your environment. A failed reproduction is a measurement of the difference between your setup and the reporter's — and that difference list is where the trigger lives.

The reporter watched it fail. Your run watched it pass. Both observations are real; the investigation is now about what differs between them.

- When reproduction fails, your next step is to enumerate differences, not to close: their data vs your data (size, content, encoding, edge values), their account/permissions/state, browser or OS, locale and timezone, config and feature flags, network conditions, scale and concurrency, time of day, software versions
- Actively close the gaps one at a time: use their actual input file, their actual account state (or a clone), the same browser, production-like data volume — re-attempting reproduction after each
- Mine the evidence from their environment instead of substituting yours: server logs at the reported timestamp, error monitoring, request IDs from the report, screenshots and exact steps
- Ask the reporter targeted questions derived from your difference list when you can't close a gap yourself
- Report status honestly: "did not reproduce under <conditions>; differences not yet ruled out: <list>" — never "works as expected" or "may have been transient" as a conclusion from a passing local run
- "Transient" is a claim about cause and requires evidence (a deploy fixed it, an outage window matches); it is not a synonym for "I don't know"

**Red flags that you're about to violate this:**
- "I tested this flow and it works fine, so the issue is resolved..."
- "Unable to reproduce — likely a transient glitch on their end..."
- "Their steps work for me; the report may be mistaken..."
- "Probably a caching issue on the user's machine..." (evidence?)
- Closing the investigation without listing a single environmental difference
- Testing with convenient sample data when the report involved their real data

---

## Why It Works

1. **It redefines what the failed repro measures.** "A measurement of the difference between environments" converts the dead-end ("nothing happened") into a dataset (the difference list), giving the AI a concrete next action where closure used to be.

2. **It grants the reporter's observation equal standing.** The AI's implicit hierarchy — my run outranks their report — is the root error; stating "both observations are real" removes the authority its own passing run was trading on.

3. **It makes "transient" a falsifiable claim.** Requiring evidence for transience (matching outage, fixing deploy) eliminates the word's main use as a polite spelling of "case closed, learned nothing."

4. **It prescribes gap-closing as a procedure.** One-difference-at-a-time reproduction attempts are bisection over environments — a mechanical path to the trigger that replaces the shrug.

## Origin

Three separate reports said invoice PDFs rendered blank, and three times an assistant generated a test invoice, saw a perfect PDF, and closed with "unable to reproduce, rendering works correctly." The trigger was invoices with more than one hundred line items — every test invoice had five. A support engineer finally attached a real customer invoice to the ticket; the repro was instant. The bug had been reported, dismissed, and re-reported for six weeks, with the difference question — "what's in *their* invoices that isn't in ours?" — never asked once.
