---
title: Read the Logs Before Theorizing
slug: read-the-logs-before-theorizing
category: debugging
tags: [universal, debugging, errors]
works_with: all
severity: high
one_liner: "AI inventing theories while the answer sits unread in existing output"
---

# Read the Logs Before Theorizing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from theorizing about a failure while the logs that explain it sit unread.

**[Copy-paste ready version](../../install/read-the-logs-before-theorizing.md)** — just the instruction block, no explanation.

## The Problem

The job failed, and the AI starts hypothesizing from the code — while the job's own log, forty lines of which describe exactly what happened, sits unopened. Application logs, CI output, server stderr, the browser console, systemd journals, the test runner's full output above the one-line summary: systems narrate their own failures constantly, and AI assistants have a strong habit of skipping the narration and going straight to authoring a theory. Reading code is the model's home turf; remembering that a log file exists, finding it, and reading 400 lines of it is not.

What gets missed is not subtle. The warning printed thirty seconds before the crash ("connection pool exhausted, waiting"). The config dump at startup showing the wrong environment loaded. The retry storm visible as the same line repeating 800 times. The line that says, in actual words, `Permission denied: /var/data/uploads`. None of this can be deduced from source code, because logs record what *happened*, and the code only says what was *supposed* to happen.

A debugging session that starts with theory and skips the logs is choosing the hard direction on purpose: reconstructing events from first principles while an eyewitness account sits in a file, unread.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read the Logs Before Theorizing

ALWAYS exhaust the output that already exists — logs, consoles, CI output, stderr, journals — before constructing any theory about a failure. Systems narrate their failures; read the narration first.

Logs record what happened. Code only records what was supposed to happen. When you skip the logs, you choose reconstruction-from-theory over an eyewitness account.

- Step one for any failure: locate and read its output channels — application log, the failing command's full stdout/stderr, the browser console and network tab, the CI job's complete log (not just the failed-step summary), service journals
- Read generously around the failure, not just the final error line: the cause frequently appears as a warning seconds or minutes earlier, and the first anomaly matters more than the last message
- Look for what's *absent* too — an expected "server started" or "job completed" line missing tells you where execution actually stopped
- Repeated lines are data: the same warning 800 times is a different story than once, so check counts and timestamps, not just unique messages
- If the log is huge, search it for the failure timestamp, error keywords, and the request/job ID, rather than declaring it too big and reverting to theory
- Only when the existing output is read and insufficient do you move to adding instrumentation or hypothesizing from code — and your theory must not contradict anything the logs already said

**Red flags that you're about to violate this:**
- "Let me look at the code to figure out what could cause this..." (the log is right there)
- "The error summary says it failed; that's all the output I need..."
- "The log file is huge, I'll reason from the code instead..."
- "The console probably doesn't have anything useful..."
- Forming a theory the existing logs already contradict
- Asking the user what happened when the system wrote down what happened

---

## Why It Works

1. **It corrects the direction of inference.** "Logs say what happened, code says what should happen" names exactly why theory-first debugging is the harder path, dissolving the pull toward the model's comfortable code-reading mode.

2. **It widens the read window.** The biggest log-reading failure isn't skipping logs entirely, it's reading only the final line; requiring the surrounding minutes and the *first* anomaly captures where causes actually appear.

3. **It makes absence and repetition first-class evidence.** Missing expected lines and 800x repeats are the two signals untrained log-readers walk past; naming them converts them into things to actively look for.

4. **It removes the too-big excuse.** Search strategies for large logs (timestamp, keywords, IDs) close the loophole where log volume becomes the justification for reverting to speculation.

## Origin

A nightly sync "randomly" stopped completing, and an assistant proposed three code-level theories across an afternoon — a race in the scheduler, a memory leak, an API change — with speculative patches for each. The job's own log, when someone finally opened it, contained the line `disk quota exceeded, retrying in 60s` repeated for four hours straight, every night, starting the night the bug began. The fix involved no code at all, and the three patches were quietly reverted.
