---
title: Check the Exit Code Before Trusting the Output
slug: check-the-exit-code-before-trusting-the-output
category: verification
tags: [universal, verification, shell]
works_with: all
severity: critical
one_liner: "Judging a command by its output's vibes while ignoring its exit code"
---

# Check the Exit Code Before Trusting the Output

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from declaring a command successful based on output that looks fine while the exit code says it failed.

**[Copy-paste ready version](../../install/check-the-exit-code-before-trusting-the-output.md)** — just the instruction block, no explanation.

## The Problem

A command prints two screens of plausible progress text and the assistant declares it succeeded — without ever checking the one bit the command itself reported about its own success. Exit codes exist precisely because output is unreliable narration: tools print cheerful logs right up to the failure, fail after their last print statement, or produce no output at all in either outcome. Meanwhile the inverse trap also fires: output containing the word "error" (in a filename, a grep match, a passing test's name) gets read as failure when the command exited 0.

Assistants skip the exit code because it isn't in the text. The output is visible and richly interpretable; the exit status is a number that has to be asked for or noticed in tool metadata, and prose-trained models judge success the way they judge stories — by how the text reads. "Looks like it worked" is a literary judgment applied to a question with a machine-readable answer.

Pipelines amplify it: in a chain of commands, a middle step fails, the tail steps run on garbage, the final output looks superficially fine, and the whole sequence gets reported as a success. The corrupted artifact then ships, because the only honest reporter in the whole transaction — the exit code — was never consulted.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check the Exit Code Before Trusting the Output

ALWAYS determine a command's exit code before characterizing it as succeeded or failed. The exit code is the command's own verdict; output is narration, and narration lies in both directions.

The core problem: judging success by how the output reads is a literary judgment applied to a machine-readable question. Tools print confident progress text and then fail, fail silently after the text ends, or print "error" strings inside perfectly successful runs.

- After any command whose success you're about to assert, confirm exit code 0 — from your tool's reported status, or explicitly via `echo $?` (or the platform equivalent) immediately after.
- No output is not success and is not failure; it's no information until paired with the exit code. Quiet tools exit nonzero without a word.
- Don't infer failure from the substring "error" either: filenames, grep matches, and log echoes contain it routinely. Direction one of this rule is the famous one, but misreading success as failure wastes cycles too.
- In pipelines and `&&`/`;` chains, know which step's status you're seeing. A pipe reports the last command's exit unless `pipefail` is set; "the chain printed output" says nothing about the middle steps.
- Distrust known liars: some wrappers, CI plugins, and scripts print errors and exit 0, or swallow child failures. Where you've seen that, verify via an artifact (the file exists, the row count changed) in addition to the code.
- When a script you wrote runs other commands, propagate failures (`set -e`/explicit checks) so its own exit code remains meaningful evidence.

**Red flags that you're about to violate this:**
- "The output looks like a normal successful run..."
- "It printed all the progress steps, so it finished..."
- "No error messages means no errors..."
- "Checking $? after every command is excessive..."
- "The last command in the pipe worked, so the pipe worked..."
- "There's the word 'error' — it must have failed..."

---

## Why It Works

1. **It names the category error.** "Literary judgment applied to a machine-readable question" reframes vibe-reading output as using the wrong instrument, not as a thoroughness lapse — which is a stronger correction.

2. **It defines silence as zero information.** Both bad inferences from empty output (assumed success, assumed failure) are blocked by requiring the pairing with an exit code before any reading is allowed.

3. **It covers both directions.** Rules against false success are common; also banning false failure (the "error" substring) prevents the model from treating string-matching as compliance.

4. **It pre-loads the pipeline trap.** Knowing that pipes report only the tail's status converts the most common multi-command misread into a specific, checkable question: whose exit code am I looking at?

## Origin

A release script printed its full checklist — build, sign, upload, tag — and the assistant reported the release shipped. The upload step had exited 1 on an expired token; the script didn't use `set -e`, so the remaining steps ran and printed their banners over the corpse. Exit code of the script: 1, visible in tool metadata, read by no one. Users spent a day downloading a release whose artifacts were the previous version with new release notes.
