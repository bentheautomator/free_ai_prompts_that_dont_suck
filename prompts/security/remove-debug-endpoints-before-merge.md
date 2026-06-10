---
title: Remove Debug Endpoints and Debug Mode Before Merge
slug: remove-debug-endpoints-before-merge
category: security
tags: [universal, security]
works_with: all
severity: critical
one_liner: "AI leaving /debug routes, test backdoors, and debug=True in shipped code"
---

# Remove Debug Endpoints and Debug Mode Before Merge

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI-added diagnostic routes, bypass flags, and framework debug modes from shipping.

**[Copy-paste ready version](../../install/remove-debug-endpoints-before-merge.md)** — just the instruction block, no explanation.

## The Problem

Mid-task, the AI gives itself tools: a `/debug/state` route that dumps internal objects, a `/test-login?user=admin` shortcut to skip the auth flow it finds tedious, an `?skip_validation=1` query flag, a `/api/dev/reset-db` convenience. These are genuinely useful for the next twenty minutes and catastrophic forever after, because routes added in a working session don't announce themselves at review time. They sit in the same diff as the feature, unauthenticated by construction (that was the point), and they ship.

The framework-level version is `app.run(debug=True)` in Flask or `DEBUG = True` in Django committed to the main settings file. Flask's debug mode is not just verbose logging: it serves the Werkzeug interactive debugger, which executes arbitrary Python in the browser, with a PIN that has known bypass history. Django's debug pages happily print settings, environment fragments, and query details to anyone who triggers an error. AI assistants enable these to see a stack trace and rarely think to scope the change.

The pattern to enforce: diagnostic capability is fine during a session, but it must be torn down or properly gated before the work is called done, and the teardown must be verifiable rather than remembered.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Remove Debug Endpoints and Debug Mode Before Merge

NEVER leave debugging affordances in completed work. Any route, flag, or mode you add to help yourself debug must be removed, or explicitly environment-gated, before the task is done, and disclosed either way.

Debug endpoints are unauthenticated by design and invisible in review by accident. They ship.

- Do not create routes like `/debug/*`, `/test-login`, `/dev/reset`, or magic query parameters (`?skip_auth=1`, `?as_user=`) as throwaway aids. If you create one anyway, removing it is part of the task, not a follow-up.
- Never commit `debug=True` (Flask), `DEBUG = True` (Django), or equivalents in code or shared config. Flask debug mode is an in-browser code execution console, not a log level. Debug flags belong in environment variables, with the committed default being off.
- Auth-bypass test users, hardcoded "dev tokens," and `if (user === 'test') return true` shortcuts count as debug affordances. Same rule.
- If a diagnostic endpoint should exist permanently (health checks, build info), it gets the production treatment: behind auth where appropriate, minimal output (no config dumps, no env, no object internals), and a deliberate decision about exposure.
- Before declaring any task complete, re-scan your own diff for routes, flags, conditionals, and config you added for debugging, and state in your summary either "removed" or "kept, gated by X, because Y."
- If you find someone else's leftover debug endpoint while working, flag it; do not assume it's intentional.

**Red flags that you're about to violate this:**
- "This route makes testing so much easier, I'll leave it for the team..."
- "debug=True is fine here, this is the dev settings file... I think..."
- "I'll mark the backdoor with a TODO so someone removes it later..."
- "Nobody will discover the endpoint, it's not linked anywhere..."
- "The test user only works in staging anyway... probably..."
- "Tearing this down now would just slow the next debugging session..."

---

## Why It Works

1. **It builds teardown into the definition of done.** The failure isn't creating the debug route, it's the missing cleanup step. Making removal part of task completion gives the cleanup a trigger that doesn't rely on memory.

2. **It forces disclosure with a forced choice.** "Removed, or kept and gated because Y" in the summary means a human sees every debugging affordance, converting an invisible risk into a reviewable line.

3. **It corrects the Flask debug misconception specifically.** AIs model `debug=True` as "more logs." Naming it as an in-browser code execution console changes the perceived stakes to match reality.

4. **It rejects security-by-obscurity for unlinked routes.** Route enumeration and JS bundle scraping find "hidden" endpoints routinely; saying so removes the AI's main comfort argument.

## Origin

To test a notification feature without clicking through login, an assistant added `/api/test/impersonate?email=` and used it productively all afternoon. It went out in the feature PR, unremarked, and lived in production for months until an automated scanner tried common paths and started minting sessions for arbitrary accounts. The postmortem's first action item was procedural, not technical: debugging aids must be declared in the PR description or not exist.
