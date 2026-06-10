---
title: Use the Project Logger
slug: use-the-project-logger
category: code-quality
tags: [universal, logging]
works_with: all
severity: medium
one_liner: "AI logging with print and console.log in codebases that have a real logger"
---

# Use the Project Logger

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from bypassing the project's logging infrastructure with raw print and console calls.

**[Copy-paste ready version](../../install/use-the-project-logger.md)** — just the instruction block, no explanation.

## The Problem

The codebase has a configured logger — `structlog` with request IDs bound, or `winston` shipping JSON to an aggregator, or `zerolog` with levels wired to environment. The AI, adding a feature that should log something, writes `print(f"Processing order {order_id}")`. Or `console.log`. Raw output calls are the most statistically common logging in training data because most training data is tutorials, and tutorials don't have logging infrastructure. Your production service does.

The bypassed machinery is the whole point of the machinery. The print statement has no level, so it can't be silenced in production or surfaced in debugging. It misses the JSON formatting, so the aggregator ingests it as an unparseable string that matches no queries. It lacks the bound context — request ID, user ID, trace ID — so it can't be correlated with anything during the incident where someone actually needs it. In some setups it doesn't even reach the same destination: stdout goes one place, the logging pipeline goes another, and the AI's messages effectively vanish. A close cousin of the same failure: instantiating a fresh logger with default config (`logging.basicConfig()`, `new Logger()`) instead of using the project's factory, which quietly forks the logging configuration.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use the Project Logger

NEVER log with raw `print`, `console.log`, `fmt.Println`, `System.out`, or `echo` in a codebase that has logging infrastructure. Find how this project logs and log that way.

Raw output bypasses everything the logging setup provides: levels, structured formatting, bound request context, and routing. A print statement is invisible to the aggregator, unfilterable in production, and uncorrelatable during incidents — which is to say, useless exactly when logs matter.

**When adding any log output:**
- Find the project's pattern first: search for `logger`, `log.`, `getLogger`, `createLogger` and copy how an existing module obtains its logger — module-level instance, injected dependency, factory call, whatever the convention is
- Never construct a fresh logger with default config (`logging.basicConfig`, `new winston.Logger()`) when a project factory or shared instance exists — that forks the configuration
- Use the project's conventions for the message itself: structured fields vs interpolated strings (`logger.info("order processed", order_id=oid)` vs f-strings, if that's the house style), message casing, and which context fields get attached
- Choose levels the way the codebase does: `debug` for diagnostic detail, `info` for normal operations, `warning`/`error` per the patterns in similar code — don't log routine success at `error` or failures at `info`
- If the project genuinely has no logging setup (scripts, tiny tools), plain output is fine — this rule is about bypassing infrastructure that exists

**Red flags that you're about to violate this:**
- "I'll just print a quick status message..."
- "console.log is fine for this..."
- "I'll set up a basic logger for this module..." (the project already has one)
- "The message text is what matters, not how it's emitted..."
- "I'll log the whole object so everything's visible..." (structured fields exist for this)
- Writing a log line without having looked at how the neighboring module logs

---

## Why It Works

1. **It explains what the print actually loses.** The AI sees `print` and `logger.info` as equivalent emitters of text. Enumerating levels, structure, context, and routing shows they're different systems, one of which is connected to anything.

2. **It targets the fresh-logger variant.** "Use a logger" alone produces `logging.basicConfig()` — technically a logger, practically a config fork. Requiring the project's factory closes the loophole the literal-minded fix would exploit.

3. **It makes discovery a one-search task.** "Find how a neighboring module logs and copy it" resolves instance acquisition, message style, and level conventions in a single example — cheaper than getting any of them wrong.

4. **It bounds the rule honestly.** Demanding logging infrastructure in a 40-line script would teach the AI the rule is sometimes silly, and rules the AI considers sometimes-silly get globally discounted. The exception keeps the rule credible where it matters.

## Origin

During a production incident, responders queried the log aggregator for a failing order ID and found nothing — the retry logic involved, added by an AI session weeks earlier, logged its attempts via `print`. Those lines went to container stdout, which wasn't shipped, and carried no request ID anyway. The team debugged forty extra minutes effectively blind, then found the prints by SSHing into a pod and reading raw output like it was 2009.
