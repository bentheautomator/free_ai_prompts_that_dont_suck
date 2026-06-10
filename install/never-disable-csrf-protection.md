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
