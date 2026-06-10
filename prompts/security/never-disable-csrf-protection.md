---
title: Never Disable CSRF Protection to Fix a 403
slug: never-disable-csrf-protection
category: security
tags: [universal, security, auth]
works_with: all
severity: critical
one_liner: "AI adding csrf_exempt or disabling CSRF middleware to unblock a request"
---

# Never Disable CSRF Protection to Fix a 403

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from exempting endpoints from CSRF checks because a form or fetch got rejected.

**[Copy-paste ready version](../../install/never-disable-csrf-protection.md)** — just the instruction block, no explanation.

## The Problem

A POST returns `403 Forbidden - CSRF verification failed`, and the AI has seen the "fix" thousands of times in training data: slap `@csrf_exempt` on the Django view, add the route to Rails' `skip_before_action :verify_authenticity_token`, comment out `app.use(csurf())`, or disable the middleware globally in settings "while we figure it out." The 403 disappears. So does the protection that stops any webpage on the internet from making state-changing requests with your users' cookies — which is the whole attack CSRF tokens exist to prevent: a hidden form on evil.site submits to your `/transfer` endpoint, and the victim's browser helpfully attaches their session cookie.

The error is almost always the application failing to *send* the token, not the protection being wrong: the frontend fetch is missing the `X-CSRF-Token` header, the template forgot `{% csrf_token %}`, the SPA never reads the cookie the framework set, or a webhook endpoint genuinely needs a different auth model. The AI exempts instead of fixing the sender because the exemption is one decorator and the real fix requires understanding the token flow. Exemptions also never get removed — there is no error reminding anyone the endpoint is unprotected.

CSRF still matters in the cookie-session world most apps actually live in. The only honest exemptions are endpoints authenticated by something browsers don't auto-attach.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Disable CSRF Protection to Fix a 403

NEVER fix a CSRF failure by exempting the endpoint or disabling the middleware. The error means the token isn't being sent; fix the sender.

CSRF protection is what stops arbitrary websites from making state-changing requests with your users' session cookies. An exempt endpoint is writable by any page on the internet a logged-in user visits.

- Do not add `@csrf_exempt`, `skip_before_action :verify_authenticity_token`, `csrf().disable()` (Spring), `WTF_CSRF_ENABLED = False`, or remove `csurf`/framework CSRF middleware to make a request succeed.
- Diagnose the sender instead: forms need the token field (`{% csrf_token %}`, `@csrf` in Blade); fetch/axios calls need the token header (read it from the cookie or a meta tag and send `X-CSRF-Token`); axios can be configured once with `xsrfCookieName`/`xsrfHeaderName`. The framework docs have an exact recipe for SPAs — use it.
- In tests, use the framework's test client mechanisms (which handle tokens) rather than disabling CSRF app-wide in the test settings and then copying those settings to prod.
- Legitimate exemptions exist only for endpoints not authenticated by cookies: webhook receivers verified by signature, token-authenticated APIs (`Authorization: Bearer ...`). When exempting such an endpoint, the alternative authentication must already be implemented, and add a comment stating why the exemption is safe.
- Cookie-session APIs need CSRF protection even if they're "APIs": if the browser attaches the auth automatically, the attack works. `SameSite=Lax` cookies reduce exposure but have carve-outs; treat SameSite as a second layer, not the replacement.
- Never set the CSRF cookie to be readable cross-site or echo the token into CORS-exposed responses to "simplify" the SPA integration.

**Red flags that you're about to violate this:**
- "csrf_exempt unblocks the frontend team right now..."
- "This is a JSON API, CSRF is a forms-era problem..."
- "SameSite cookies made CSRF tokens redundant..."
- "I'll disable it globally in dev settings to stop the noise..."
- "The mobile app can't do tokens, so the endpoint has to be exempt..."
- "We'll re-enable verification once the SPA integration stabilizes..."

---

## Why It Works

1. **It relocates the bug to the sender.** The AI exempts because it models the 403 as the middleware misbehaving; "the token isn't being sent" points at the actual defect and makes the exemption visibly the wrong layer.

2. **It hands over the SPA recipe.** Missing-header-in-fetch is the dominant real cause, and the cookie-to-header pattern is the fix the AI doesn't know to reach for; once provided, the exemption loses its convenience advantage.

3. **It defines the legitimate exemption precisely.** "Not cookie-authenticated, alternative auth already implemented, comment required" lets webhooks through without opening the door for "it's a JSON API" hand-waving.

4. **It demotes SameSite from fix to layer.** "SameSite solved CSRF" is the modern rationalization; stating its carve-outs keeps the token check in place.

## Origin

An SPA migration left dozens of fetch calls without the CSRF header, and rather than configure axios once, an assistant exempted each failing endpoint as it was reported — including, eventually, the email-change and password-change routes. A security review eighteen months later found 23 exempt state-changing endpoints and a working proof-of-concept page that changed a logged-in victim's email address from a forum post. The actual fix had been three lines of axios configuration the whole time.
