---
title: Treat Error Message Formats as Contracts
slug: treat-error-message-formats-as-contracts
category: collaboration
tags: [universal, teamwork, contracts]
works_with: all
severity: high
one_liner: "Stops rewording errors and log lines that other teams' alerts parse"
---

# Treat Error Message Formats as Contracts

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from rewording error messages and log lines that other teams' alerts, dashboards, and scripts parse by exact text.

**[Copy-paste ready version](../../install/treat-error-message-formats-as-contracts.md)** — just the instruction block, no explanation.

## The Problem

Somewhere outside the repo, a PagerDuty alert matches on `"payment declined: insufficient funds"`. A log-based dashboard counts lines containing `ERROR processing batch`. A support team's runbook says "search the logs for `TIMEOUT_UPSTREAM`." None of this is visible from the code. The AI, touching a function for unrelated reasons, improves an error message — better grammar, more context, structured fields, a friendlier tone. The message is genuinely better. The alert that matched the old text now matches nothing, and the failure it watched for has become invisible.

This is the cruelest class of break because nothing fails. No test goes red, no exception is thrown, no consumer crashes. A monitoring system simply goes quiet, and going quiet looks exactly like things going well. The other team discovers their alert was dead when the incident it should have caught runs for four hours instead of four minutes — and the postmortem traces it to a wording change in a commit titled "minor cleanup."

The AI does this by default because error strings look like prose, and prose looks editable. It has no way to see the grep on the other end. In a shared system, an error message that has shipped is not prose — it's an interface with whoever is parsing it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Treat Error Message Formats as Contracts

NEVER reword, restructure, or change the severity/level of an existing error message or log line as a side effect of other work. Once shipped, error text is an interface: alerts, dashboards, runbooks, and scripts on other teams match it by exact string.

The break is silent — a monitor matching old text doesn't fail, it just stops firing.

- When editing a function, leave its existing error messages, log lines, error codes, and log levels byte-for-byte alone unless changing them is the task.
- New messages are yours to write; existing messages belong to whoever is parsing them.
- This includes "harmless" edits: punctuation, capitalization, switching to structured logging, changing `ERROR` to `WARN`, reordering interpolated values, translating, or adding a prefix.
- Error codes, exception class names, and machine-readable error fields are even harder contracts than the human text. Never rename them in passing.
- If the task does require changing a shipped message, flag it explicitly: old text, new text, and a note that downstream alerting and runbooks may match the old string and need updating.
- When adding context to an error, prefer appending new fields or a new line over rewriting the line that exists.

**Red flags that you're about to violate this:**
- "This error message is unclear; I'll improve it while I'm here."
- "Switching this to structured logging is a strict upgrade."
- "It's just a log line, nothing depends on log lines."
- "This is clearly WARN-level, not ERROR — easy fix."
- "I'll standardize all these messages to the same format."

---

## Why It Works

1. **It reframes shipped strings as interfaces**, which flips the AI's default ("prose is freely editable") into the correct model ("someone greps for this").
2. **It names the silent failure mechanism** — a dead alert produces no signal — so the AI can't reason that "if this mattered, something would break."
3. **It draws the line at shipped vs. new**, preserving full freedom to write good messages going forward, so the rule costs nothing where there's no contract yet.
4. **It converts unavoidable changes into announcements**, giving the humans on the parsing end a chance to update their matchers before the old string disappears.

## Origin

During a refactor, an assistant standardized a service's log lines, changing `FATAL: queue consumer died` to a structured `{"level":"error","msg":"consumer terminated"}`. The SRE team's highest-severity alert matched the old string. Three weeks later the consumer died on a Friday night and nothing paged; messages backed up for six hours before a customer noticed. The alert had been "passing" the whole time, in the sense that silence and success are indistinguishable.
