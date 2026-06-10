---
title: Never Return Stack Traces or Internal Errors to Clients
slug: no-stack-traces-to-clients
category: security
tags: [universal, security, logging]
works_with: all
severity: high
one_liner: "AI sending err.message, stack traces, and SQL errors in API responses"
---

# Never Return Stack Traces or Internal Errors to Clients

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from leaking internals through error responses while making errors "more helpful."

**[Copy-paste ready version](../../install/no-stack-traces-to-clients.md)** — just the instruction block, no explanation.

## The Problem

When an AI writes a catch block, helpfulness is its instinct: `res.status(500).json({ error: err.message, stack: err.stack })`, or Python's `return jsonify(error=str(e)), 500`. During development this is great — the bug is right there in the response. In production it's a reconnaissance service. Database errors disclose table and column names ("duplicate key violates constraint users_email_key"), file errors disclose filesystem layout, stack traces disclose framework versions, file paths, and code structure, and validation errors sometimes echo back the failing query itself. Attackers iterate on inputs and read your error responses like documentation, because that's what you've made them.

The subtler variant is differential errors: "user not found" versus "wrong password" turns a login form into a username oracle; different errors for "file missing" versus "permission denied" map your filesystem. AI assistants produce distinct, descriptive errors for every branch because distinctness reads as quality code. There's also the framework-level version — leaving Express's default error handler, Django's `DEBUG=True` page, or Rails' development error pages active in production config, which the AI does when it copies dev settings forward.

The pattern that works: log the detail server-side with an ID, return the ID and a generic message to the client.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Return Stack Traces or Internal Errors to Clients

NEVER send internal error details in HTTP responses. Log the full error server-side with a correlation ID; return the ID and a generic message to the client.

Error responses are documentation for attackers: stack traces map your code, database errors map your schema, and distinct error messages become oracles.

- In catch blocks: `logger.error({err, requestId})` server-side, then respond `{ "error": "Internal error", "requestId": "..." }`. Never include `err.message`, `err.stack`, exception class names, SQL text, or file paths in the response body for unexpected errors.
- `err.message` is not safe just because it's short: driver and library messages embed table names, constraint names, hosts, and paths. Treat any message you didn't write as internal.
- Expected, user-fixable errors (validation failures, "name is required") should be specific — that's UX, not leakage. The line: messages you authored about THEIR input are fine; messages the system generated about YOUR internals are not.
- Auth flows must return identical errors and similar timing for "no such user" and "wrong password" ("Invalid email or password"), and registration/password-reset flows need the same care ("If that account exists, we sent an email").
- Set production config to suppress framework debug pages: Express error handler without stacktraces in prod, Django `DEBUG=False`, Rails `consider_all_requests_local = false`. Verify the production branch of the config, not just the default.
- GraphQL: disable verbose error extensions and stack traces in production (`includeStacktraceInErrorResponses: false`, mask internal errors); the default in several servers is chatty.
- 404 versus 403 on resources others own: prefer uniform 404 so existence isn't leaked.

**Red flags that you're about to violate this:**
- "Returning err.message makes debugging integration issues so much easier..."
- "The client team asked for descriptive errors..."
- "It's just the exception text, not a full stack trace..."
- "Telling users whether the email or the password was wrong is better UX..."
- "We'll turn off debug pages when we set up real prod config..."
- "Our API consumers are internal, they can see internals..."

---

## Why It Works

1. **It replaces helpfulness with an equally helpful pattern.** The AI leaks because it wants debuggability; the correlation-ID pattern preserves debuggability through the logging channel, so nothing is lost by complying.

2. **It draws the authored-vs-generated line.** "Be generic" alone produces useless validation errors and gets ignored; distinguishing your messages about their input from the system's messages about your internals keeps both security and UX.

3. **It names the oracle problem.** Differential login errors don't look like leaks, they look like good error handling; the username-enumeration framing is what makes the AI stop producing them.

4. **It includes the config-level leaks.** Catch blocks aren't the only emitter; debug pages and GraphQL defaults leak the same data, and the AI won't connect them to this rule unless they're listed.

## Origin

An API's catch-all handler, written to "return helpful errors during the beta," passed `err.message` through verbatim. A tester poking at a search endpoint collected database error strings that revealed the schema, then the specific ORM and its version from a stack fragment, and matched it to a known injection technique in that version. The beta label had outlived the beta by a year. The fix was an eight-line error middleware with request IDs, plus one very educational incident review.
