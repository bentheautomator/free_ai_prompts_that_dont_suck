### Keep Security Headers On

ALWAYS include baseline security headers on new web services, and NEVER fix an embedding or rendering problem by deleting a header globally. Narrow the policy to the case that needs it.

Missing headers are silent: nothing breaks, nothing warns, and each absence is a standing invitation (clickjacking, MIME confusion, protocol downgrade).

- Baseline for any new HTTP service: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` (or CSP `frame-ancestors 'none'`), `Strict-Transport-Security: max-age=31536000; includeSubDomains` on HTTPS sites, `Referrer-Policy: strict-origin-when-cross-origin`. Use the packaged bundle where it exists — `helmet()` in Express, `django.middleware.security` settings, framework defaults — rather than hand-maintaining.
- Legitimate embedding need (partner iframe, embed product): replace DENY with CSP `frame-ancestors https://partner.example.com` listing the exact origins. Do not delete the header, and do not set `ALLOWALL`-style values.
- One Helmet/middleware header causing friction: disable that single header by option (`helmet({ frameguard: false })` plus the narrowed replacement), never the whole bundle.
- HSTS issues behind proxies are almost always `X-Forwarded-Proto`/trusted-proxy misconfiguration presenting as redirect loops; fix the proxy awareness, don't strip HSTS. Be careful adding `preload` (it's hard to undo), but don't remove existing HSTS without flagging that browsers will keep enforcing it anyway until max-age lapses.
- `nosniff` "breaking" a response means the `Content-Type` is wrong; fix the type, keep the header.
- Treat any diff that removes or weakens a header in shared config (nginx, gateway, middleware) as a security change: name it explicitly in your summary with the scope of pages affected.

**Red flags that you're about to violate this:**
- "The partner embed fails with X-Frame-Options, removing it unblocks the integration..."
- "Helmet is causing weird issues, I'll drop it and add headers back as needed..."
- "HSTS is creating a redirect loop, deleting it fixes prod right now..."
- "These headers are hardening polish, the service works without them..."
- "Nobody would bother clickjacking this app..."
- "I'll allow framing everywhere since we might embed it in more places later..."
