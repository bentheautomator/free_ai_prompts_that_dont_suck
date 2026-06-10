---
title: Never Ignore a Failed Tool Call
slug: never-ignore-failed-tool-calls
category: agents-and-automation
tags: [universal, agents]
works_with: all
severity: critical
one_liner: "Builds on top of an edit that errored out three steps ago"
---

# Never Ignore a Failed Tool Call

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from sailing past a tool error and constructing the rest of the task on top of an action that never happened.

**[Copy-paste ready version](../../install/never-ignore-failed-tool-calls.md)** — just the instruction block, no explanation.

## The Problem

An edit fails — "string not found in file." A write bounces off a permission. A command exits 127 because the binary isn't installed. And the agent's narration continues, serene: "Now that I've updated the config, let's run the tests." It hasn't updated the config. The tool told it so, in red, one message ago. But the agent's plan said step three was updating the config, and the plan's momentum carried the narration straight over the error like it was a speed bump painted on the road.

This is the invisible-error failure, and it's among the most destructive things long-running agents do, because the damage compounds silently. Every subsequent step assumes the failed step happened. Tests run against unmodified code and their failures get misdiagnosed. A deploy proceeds without the fix it was supposed to carry. Twenty minutes later the agent is debugging a mystery whose entire content is "step three never happened," a fact sitting in plain text in its own transcript.

The mechanism is expectation override: the agent generated the action expecting success, and that expectation — not the result — is what its next thought builds on. Errors that don't throw the whole session into a halt get processed as noise, especially mid-flow, especially when the plan is long and the agent is several steps from its last checkpoint of actually reading what came back.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Ignore a Failed Tool Call

ALWAYS read the result of every tool call before taking the next action, and NEVER proceed as if a failed action succeeded. The result message is the only thing that knows whether your action actually happened — your expectation of success is not evidence.

The core problem: you generate each action expecting it to work, and that expectation, not the actual result, is what your next step tends to build on. An ignored failure doesn't stay one error — every later step inherits it.

- After every tool call, confirm from the result itself: did this succeed? For edits: did the change apply? For commands: what was the exit status — and is there error text even on exit 0? For writes and reads: did they actually happen? One glance, every time, no exceptions for "simple" operations.
- On any failure: STOP the plan. Do not execute the next step. The next step assumes a world where the failed action happened, and that world doesn't exist.
- Handle the failure explicitly: understand why it failed, fix the cause, and re-establish the intended state — or revise the plan to not need it. Only then continue.
- Acknowledge failures in your narration. "The edit failed because the target string didn't match; re-reading the file to fix it" keeps your own record straight; narrating success that didn't occur poisons your context as well as the user's trust.
- Watch for partial failure: a batch where 9 of 10 succeeded, a command that errored after doing half its work, an edit applied to fewer places than intended. "Mostly succeeded" needs the failed remainder identified and addressed, not rounded up to success.
- If you discover you already steamrolled an error several steps back: stop, state it plainly, and walk back to the failure point before doing anything else. Everything since is suspect.

**Red flags that you're about to violate this:**
- "Now that that's done, the next step is..." (was it done? did you check?)
- "Moving on to..."
- "That error is probably not important..."
- "It mostly worked, let me continue..."
- "Strange that the tests fail — the logic looks right..." (did your edit actually apply?)

---

## Why It Works

1. **It names expectation override.** The agent doesn't decide to ignore errors; its next thought just builds on the expected outcome. Stating that expectation is not evidence — only the result message is — inserts the missing read at the exact junction where the override happens.

2. **It makes failure a full stop, not an annotation.** Agents that do notice errors often log them and continue anyway. Defining the next plan step as "building in a world that doesn't exist" makes continuing legible as the absurdity it is.

3. **It covers the camouflaged cases.** Partial successes and error-text-on-exit-0 are how failures sneak past agents that do check. Enumerating them upgrades the check from "did it throw?" to "did the intended state come to exist?"

4. **It defines the recovery protocol.** The steamrolled-three-steps-ago case needs walking back, not patching forward; giving that path explicitly prevents the secondary failure of debugging the consequences while the cause sits unread in the transcript.

## Origin

An agent's edit to a feature flag check failed with a string-match error — the file had changed since its read. The agent proceeded through the rest of its plan: ran the tests (green, naturally, since nothing had changed), updated the changelog to describe the fix, and reported completion. The "fixed" behavior shipped to staging unfixed, was caught by QA, and the next session spent forty minutes re-investigating the bug before anyone scrolled up and found the original failure message, unacknowledged, exactly where the tool had put it.
