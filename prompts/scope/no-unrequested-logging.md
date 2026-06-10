---
title: No Unrequested Logging
slug: no-unrequested-logging
category: scope
tags: [universal, scope]
works_with: all
severity: medium
one_liner: "AI sprinkling log statements through code as a side effect of editing it"
---

# No Unrequested Logging

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from peppering code with log statements nobody asked for while doing unrelated work.

**[Copy-paste ready version](../../install/no-unrequested-logging.md)** — just the instruction block, no explanation.

## The Problem

The function you asked the AI to modify now announces itself: `logger.info("Processing user data...")` at the top, `logger.debug(f"Payload: {payload}")` in the middle, `logger.info("Done processing")` at the end. Sometimes it's `console.log`, sometimes `print`. You asked for a behavior change; you got a behavior change plus narration.

The AI adds these because logged code looks observable and observable sounds professional. The costs are real, though. Log noise is a tax on everyone who reads logs to find actual problems — a system that logs "Processing..." thousands of times an hour has made its signal quieter. Logging full payloads is how emails, tokens, and access keys end up in log storage with different retention and access rules than the database they came from, which in regulated environments is an incident, not a style issue. And in hot paths, eager string formatting and I/O have measurable cost.

What gets logged, at what level, in what format is an operational policy. Teams have conventions: structured fields, correlation IDs, level discipline. Freelance log statements from an AI follow none of them.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Unrequested Logging

Do not add logging, print statements, or debug output unless the request asks for it. Code you edit for other reasons keeps exactly the log statements it had.

The core problem: ad-hoc log statements bury real signals in noise, leak payload data into log storage, and impose an observability "style" the project never chose.

- No entry/exit announcements ("Starting X...", "X complete") around functions you write or modify
- No logging of payloads, records, or variables for visibility; logged data is stored, retained, and accessed under different rules than the source data, and secrets or PII in logs are incidents
- No `print`/`console.log` left behind from your own debugging during the task
- Do not change levels, formats, or messages of existing log lines in passing
- If the task involves diagnosing a problem, temporary instrumentation is fine while you investigate, but remove it before delivering unless asked to keep it
- If you believe a specific failure point genuinely warrants a permanent log line, propose it in one sentence with the level and message, and let the user decide

**Red flags that you're about to violate this:**
- "I'll add some logging so this is easier to debug later..."
- "A quick info line here improves observability..."
- "Logging the payload will help when something goes wrong..."
- "Good production code logs its progress..."
- "I'll leave my debug prints in, they might be useful..."

---

## Why It Works

1. **It separates investigation from delivery.** The AI's legitimate need to instrument while debugging gets explicit permission with an expiry, so "useful while I worked on it" stops becoming permanent.

2. **It reframes payload logging as data movement.** The AI evaluates a log line as text output; describing it as copying data into a store with different retention and access rules makes the PII risk concrete.

3. **It treats log policy as owned by the team.** Levels, structure, and correlation conventions exist; declaring them out of the AI's jurisdiction stops convention-free freelancing.

4. **It keeps the proposal channel open.** A genuinely valuable log point becomes a one-sentence suggestion with named semantics, so the AI loses nothing by not writing it directly.

## Origin

During a routine field addition, an assistant added "helpful" debug logging that included the full request object of a checkout endpoint. The request object contained card metadata and customer addresses, which then flowed into a log aggregator with org-wide read access and 18-month retention. The compliance review that followed consumed two engineers for most of a month. The field addition itself had been six lines.
