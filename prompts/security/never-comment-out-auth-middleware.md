---
title: Never Comment Out Auth to Debug
slug: never-comment-out-auth-middleware
category: security
tags: [universal, security, auth]
works_with: all
severity: critical
one_liner: "AI disabling auth middleware to isolate a bug and leaving it off"
---

# Never Comment Out Auth to Debug

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from disabling authentication or authorization checks as a debugging step.

**[Copy-paste ready version](../../install/never-comment-out-auth-middleware.md)** — just the instruction block, no explanation.

## The Problem

A request returns 401 and the AI wants to know if the bug is in the handler or the auth layer. The fastest experiment: comment out `app.use(requireAuth)`, or delete the `@login_required` decorator, or add an early `return next()` to the middleware. Now the handler is reachable, the actual bug gets fixed, the session moves on, and the commented-out auth ships inside a diff that's nominally about something else. Every endpoint behind that middleware is now public.

This failure is sneaky because each individual step is reasonable. Isolating variables is good debugging. The problem is that auth removal is a global, silent change with no failing test to catch it — most test suites authenticate properly or mock auth entirely, so nothing goes red when production stops checking tokens. The AI also has a tendency to "simplify" while debugging: replacing a token check with `if (true)`, hardcoding a user ID "for now," or stubbing `getCurrentUser()` to return an admin.

The 401 was probably the answer all along: an expired test token, a missing header, a misconfigured secret. Those are diagnosable without turning off the lock on the front door.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Comment Out Auth to Debug

NEVER disable, bypass, weaken, or stub out authentication or authorization to diagnose a problem. Debug with valid credentials, not with the checks removed.

Auth removal is a global change that no test will catch, and "I'll re-enable it after" is how it ships disabled.

- Do not comment out auth middleware, remove `@login_required`/`[Authorize]` decorators, add early returns to auth functions, or replace token validation with `if (true)`.
- Do not hardcode a user ID, role, or "dev user" to skip login. Do not make `getCurrentUser()` return a fixture in non-test code.
- To debug a 401/403: log why the check failed (expired? missing header? bad signature? wrong audience?), inspect the actual token at jwt.io-style decoding locally, and obtain a valid test credential. The rejection reason is the diagnosis.
- If the codebase needs an auth-less mode for local development, it must be an explicit, environment-gated mechanism (`AUTH_DISABLED=true` refused outside `NODE_ENV=development`), designed deliberately, never improvised mid-debugging.
- If you must temporarily weaken a check in a live debugging session at the user's request, re-enable it in the same session and confirm with a test that hits the endpoint unauthenticated and gets a 401. Say explicitly in your summary whether auth was touched.
- Before finishing any task, if you modified any file containing auth logic, re-read your diff specifically for weakened checks.

**Red flags that you're about to violate this:**
- "Let me bypass auth just to confirm the handler works..."
- "I'll hardcode user 1 for now so we can test the flow..."
- "The token setup is complicated, it's faster to skip the check..."
- "I'll add a TODO to restore this decorator..."
- "It's only the staging environment, auth there doesn't protect anything real..."
- "The middleware is probably the bug, so removing it is a valid test..."

---

## Why It Works

1. **It redirects the debugging instinct instead of fighting it.** The AI bypasses auth to get information. Telling it to log the rejection reason gives it better information through a safe channel.

2. **It covers the soft bypasses.** Hardcoded user IDs and stubbed `getCurrentUser()` don't look like "disabling auth," so a naive rule misses them. Enumerating them closes the gap.

3. **It requires a verification step on re-enable.** "I turned it back on" without an unauthenticated-request test is exactly how half-restored auth ships. The 401 check makes restoration observable.

4. **It forces disclosure.** Requiring the summary to state whether auth was touched means a human reviews that specific risk even in a large diff.

## Origin

While chasing a serialization bug, an assistant commented out the JWT middleware on an API router "to rule it out," fixed the real bug two files away, and produced a clean-looking diff. The commented-out line rode along in the same commit. The endpoints served account data publicly for eleven days until an integration partner asked why their requests worked without a token. The middleware comment still said `// TEMP: re-enable`.
