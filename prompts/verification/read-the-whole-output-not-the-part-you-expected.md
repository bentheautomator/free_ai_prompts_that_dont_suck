---
title: Read the Whole Output Not the Part You Expected
slug: read-the-whole-output-not-the-part-you-expected
category: verification
tags: [universal, verification, output]
works_with: all
severity: high
one_liner: "Skimming command output for the hoped-for line and paraphrasing the rest away"
---

# Read the Whole Output Not the Part You Expected

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from summarizing command output it pattern-matched instead of read.

**[Copy-paste ready version](../../install/read-the-whole-output-not-the-part-you-expected.md)** — just the instruction block, no explanation.

## The Problem

The command ran. The output is right there in the transcript. And the assistant's summary of it — "installed successfully," "all checks passed" — describes the output it expected rather than the output it got. The actual text said `47 packages installed, 3 warnings, peer dependency conflict`, or `OK (12 tests, 4 skipped)`, or printed a deprecation notice that names exactly the API the session is about to spend an hour debugging. The evidence was delivered; it just wasn't read.

This happens because models pattern-match output against the success shape they anticipated. The eye finds "OK" or "success" or the absence of a stack trace, declares the expectation met, and the summary gets generated from the expectation. Warnings, skip counts, "0 rows affected," partial-failure lines, and anything after the first screen of output get paraphrased out of existence — not suppressed deliberately, just never ingested.

The damage is doubled because the user trusts the paraphrase more than they'd trust a raw dump: it reads as "the assistant checked this." A summary that drops the three warnings isn't a shorter version of the truth; it's a different claim wearing the truth's formatting.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read the Whole Output Not the Part You Expected

ALWAYS read command output in full before characterizing it. Your summary must be derived from the text that came back, not from the text you expected to come back.

The core problem: anticipating success makes you pattern-match output against the success shape — you find the "OK," stop reading, and paraphrase the rest from imagination. The lines that didn't match your expectation are precisely the ones that matter.

- Read to the end. Warnings, skipped counts, partial failures, and "but..." lines cluster after the headline. Long output is not an exemption; it's where things hide.
- Quote the load-bearing lines in your summary: exact counts, exact warning text, exact final status line. If your summary contains a number or a status word, it must appear in the output, not merely be consistent with it.
- Report what surprised you. Skips you didn't expect, "0 rows affected," deprecation notices, "using cached version," retries — anything that diverges from the clean run you imagined goes in the report, even if you believe it's benign.
- Never round mixed results up: "succeeded with 3 warnings" is not "succeeded." "12 passed, 4 skipped" is not "all tests pass."
- If you truncated, paged, or piped output through `head`/`tail`/`grep`, say so — your summary covers what you saw, and you chose not to see the rest.
- When output contradicts your expectation, the output wins. Update the claim, not the reading.

**Red flags that you're about to violate this:**
- "I saw 'BUILD SUCCESSFUL', that's the part that matters..."
- "The warnings are probably the usual noise..."
- "I'll summarize from what this command normally prints..."
- "It scrolled past, but nothing red jumped out..."
- "Skipped tests are basically passing tests..."
- "The user wants the upshot, not the details..."

---

## Why It Works

1. **It names the pattern-match shortcut.** The failure isn't lying — it's generating the summary from the expectation instead of the observation. Calling out that exact mechanism interrupts it at the moment of summarizing.

2. **Quoting is incorruptible.** Exact counts and verbatim status lines can only come from the output; requiring them forces ingestion of the text the paraphrase would have skipped.

3. **It defines surprise as signal.** "Report what diverged from the imagined clean run" gives the model a positive search target — anomalies — instead of a vague duty to be thorough.

4. **It bans the round-up.** "Succeeded with warnings ≠ succeeded" closes the specific lossy compression that turns mixed results into clean claims.

## Origin

A dependency upgrade session ended with "installed cleanly, no issues." The install output — present in full in the transcript — included a peer-dependency warning naming the exact version conflict that broke the build in CI an hour later. Nobody had hidden anything; the warning sat in plain text between the assistant's command and the assistant's summary. The fix took five minutes. The trust repair took longer, because now every "no issues" in that team's sessions gets re-read by a human.
