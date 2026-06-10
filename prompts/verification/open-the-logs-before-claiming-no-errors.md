---
title: Open the Logs Before Claiming No Errors
slug: open-the-logs-before-claiming-no-errors
category: verification
tags: [universal, verification, logs]
works_with: all
severity: high
one_liner: "Asserting 'no errors' about logs and consoles that were never opened"
---

# Open the Logs Before Claiming No Errors

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from claiming "runs without errors" when the places errors appear were never checked.

**[Copy-paste ready version](../../install/open-the-logs-before-claiming-no-errors.md)** — just the instruction block, no explanation.

## The Problem

"Runs cleanly, no errors." Where would the errors have appeared, exactly? Not in the foreground output the assistant watched — the app logs exceptions to a file, the worker reports failures to stderr that got swallowed by the runner, the browser console is carrying three red stack traces nobody opened, the framework caught the exception and logged it at ERROR level while the page rendered anyway. "No errors" was a claim about the system; the assistant observed one of its four output channels and pronounced the rest healthy by silence.

The behavior is built on an asymmetry: errors that print in your face are impossible to miss, so the absence of in-your-face errors feels like the absence of errors. But modern systems are designed to keep failures out of your face — caught-and-logged exceptions, dead-letter queues, error boundaries, retry loops that mask the first four failures. The quieter the system, the more deliberately you have to go looking. Assistants don't go looking, because the claim was already writable without the trip.

The user reads "no errors" as "the logs are clean," because that's what it means when a human says it after actually checking. The gap between the two usages surfaces later, in production monitoring, as a backlog of errors timestamped to the session that reported none.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Open the Logs Before Claiming No Errors

NEVER claim "no errors," "runs cleanly," or "nothing in the logs" unless you identified where this system records errors and actually looked there, after your change ran.

The core problem: systems are built to keep errors out of the foreground — caught exceptions go to log files, browser consoles, stderr, and error trackers. Watching one quiet channel and declaring the system error-free is testimony about places you never visited.

- Before the claim, enumerate the error channels this system has: application log files, stderr (separately from stdout), the browser devtools console for anything with a frontend, the framework's error log, worker/queue failure records, error-tracking services if present.
- Check the relevant ones after exercising your change — filtered to the time window of your run, so you're not crediting yourself with pre-existing noise or blaming yourself for it.
- Greppable evidence beats impressions: search the window for ERROR, WARN, exception, traceback, and the failure vocabulary of this stack. Say what you searched and what came back.
- A rendered page is not a clean console. Error boundaries and caught promises let UIs look perfect over a console full of red. For frontend claims, the console check is mandatory.
- Scope honestly when access is partial: "stdout and the app log are clean; I cannot see the error tracker from here" is a verifiable claim. "No errors" while blind to half the channels is not.
- Warnings you find don't get rounded down to nothing. "Clean except two deprecation warnings, quoted below" is the accurate sentence.

**Red flags that you're about to violate this:**
- "Nothing printed, so nothing went wrong..."
- "The page rendered fine; the console is surely fine too..."
- "If there were errors, I'd have seen them..."
- "Tailing the log file is extra ceremony for a small change..."
- "The framework would have crashed if something failed..."
- "stderr is probably empty — stdout was..."

---

## Why It Works

1. **It converts "no errors" from an impression into an itinerary.** Requiring the channel list first means the claim now describes completed visits to named places, not the silence of wherever the model happened to be watching.

2. **It exploits the time-window filter.** Scoping the log check to the run's window makes the check fast and the result attributable — removing both the "too much noise" excuse and the ambiguity about whose errors they are.

3. **It targets the rendered-page illusion by name.** The working UI over a red console is the single most common version of this failure; making the console check mandatory for frontend claims closes it specifically.

4. **It legitimizes the partial-visibility report.** Scoped honesty ("these channels clean, that one unreachable") gives the model a truthful sentence that still sounds competent, so the inflated one loses its appeal.

## Origin

An assistant integrated a new analytics call into a checkout flow, clicked through the flow, saw it complete, and reported "works end to end, no errors." The browser console — never opened — showed the analytics call throwing on every page load and an error boundary eating it. The thrown error also aborted a queued inventory update, which is how the team eventually found it: three weeks of slightly wrong stock counts, traced back to a session whose summary contained the words "no errors" about a console that was on fire the entire time.
