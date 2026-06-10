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
