---
title: Never Log Credentials or Full Request Bodies
slug: no-secrets-in-logs
category: security
tags: [universal, security, logging]
works_with: all
severity: high
one_liner: "AI logging entire request objects with passwords and tokens inside"
---

# Never Log Credentials or Full Request Bodies

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from dumping passwords, tokens, and headers into application logs while debugging.

**[Copy-paste ready version](../../install/no-secrets-in-logs.md)** — just the instruction block, no explanation.

## The Problem

Something fails in a request handler and the AI wants visibility, so it adds `logger.info(f"Request: {request.body}")` or `console.log('headers:', req.headers)`. On a login endpoint, that line writes every user's plaintext password into the log stream. On an API route, it writes every bearer token and session cookie. Logs then flow to places with far weaker access control than the database: aggregation services, S3 buckets, developer laptops running `kubectl logs`, third-party log vendors with their own retention policies.

This is the single most common security regression in AI-assisted debugging because logging is the AI's primary diagnostic tool and "log everything" maximizes the chance of catching the bug. The whole-object dump (`JSON.stringify(req.body)`, `print(vars(request))`) is especially attractive because the AI doesn't know which field matters yet. Debug logging also has the highest ship rate of any temporary code: it's invisible in normal operation, so nothing prompts its removal.

A password in a log is a breach with extra steps. Compliance regimes treat it as one, and so should your instructions file.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Log Credentials or Full Request Bodies

NEVER log secrets, and never log whole request/response objects on endpoints that can carry them. Log specific, named, non-sensitive fields instead.

Logs have weaker access control and longer retention than your database. A token in a log is a token leaked.

- Never log: passwords, tokens (bearer, refresh, session, CSRF), API keys, `Authorization`/`Cookie`/`Set-Cookie` headers, security answers, OTP codes, private keys, or full card numbers.
- Do not dump containers that might hold them: `req.body`, `req.headers`, `request.POST`, config objects, env (`process.env`, `os.environ`), caught exception objects from auth libraries, or axios/fetch error objects (which embed the request, headers included).
- Log selectively: `logger.info("login failed", {username, reason})`, not the body. If a sensitive value must be referenced, log a redacted form (`tok_...last4`) or a hash, and say which.
- On auth endpoints specifically, the password field is present in the body by definition. Never add body logging there, even at debug level; debug level runs in prod more often than anyone admits.
- When adding diagnostic logging during a session, list every log line you added in your summary so they can be reviewed and removed.
- If the project has a redaction/allowlist mechanism in its logger, route new logging through it instead of around it.

**Red flags that you're about to violate this:**
- "I'll log the whole request just while we track this down..."
- "It's debug level, it won't show up in production..."
- "Logging the headers will show us if the token is being sent..."
- "Our logs are internal, only engineers can read them..."
- "I'll dump the config object to see what's actually loaded..."
- "One verbose log line is the fastest way to see everything at once..."

---

## Why It Works

1. **It targets containers, not just values.** The AI never types `log(password)`; it types `log(req.body)` and the password comes along. Banning the dump-the-object pattern addresses how the leak actually happens.

2. **It names the error-object trap.** HTTP client errors in Node embed full request config including auth headers, and `logger.error(err)` leaks them. Almost no one teaches this; the instruction does.

3. **It dismantles the "debug level" comfort blanket.** Debug logging in production is common enough that level-based safety is fiction, and saying so removes the rationalization.

4. **It creates a removal trigger.** Requiring added log lines to be listed in the summary gives temporary logging an explicit end-of-life moment instead of relying on memory.

## Origin

Debugging an intermittent login failure, an assistant added a single line logging the parsed request body "to see the malformed payloads." The fix shipped with the logging still in. For six weeks, every login wrote `{"email": ..., "password": ...}` to a third-party log platform with team-wide access and 90-day retention. The incident response involved forced password resets for every user who logged in during the window, which was most of them.
