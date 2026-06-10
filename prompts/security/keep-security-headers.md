---
title: Keep Security Headers On
slug: keep-security-headers
category: security
tags: [universal, security, headers]
works_with: all
severity: high
one_liner: "AI removing X-Frame-Options or HSTS because something stopped rendering"
---

# Keep Security Headers On

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from stripping clickjacking, MIME-sniffing, and HTTPS-enforcement headers, or omitting them from new services.

**[Copy-paste ready version](../../install/keep-security-headers.md)** — just the instruction block, no explanation.

## The Problem

Security headers fail in two directions with AI assistants. Direction one: omission. A new Express/Flask/nginx service gets scaffolded without `X-Frame-Options`/`frame-ancestors`, `X-Content-Type-Options: nosniff`, `Strict-Transport-Security`, or a `Referrer-Policy`, because none of them affect whether the demo works. Each absence is an enabled attack: frameable pages invite clickjacking (your transfer button under an invisible overlay), sniffable responses let browsers promote uploads to executable types, and missing HSTS leaves first connections and downgrade tricks on plaintext HTTP.

Direction two: subtraction. Something breaks — the app won't render inside a partner's iframe, an embed integration fails, a redirect loop appears behind a load balancer — and the header is the visible cause. The AI deletes `X-Frame-Options` globally (instead of allowlisting the one partner origin via `frame-ancestors`), or disables Helmet entirely because one of its dozen headers caused friction, or strips HSTS because the team "needs HTTP for a while" (the redirect loop was actually a missing `X-Forwarded-Proto` config). Deleting the header fixes the symptom and disables the control for every page, every user, permanently — with no error message ever announcing it.

Headers are one middleware line. The rule is: present by default on new services, and narrowed rather than removed when they conflict with a requirement.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It converts every removal into a narrowing.** The AI subtracts headers because the broken integration is concrete and the protection is abstract; providing the narrowed form (`frame-ancestors` with one origin, single-header opt-outs) gives a fix that solves the same problem without the global disable.

2. **It redirects blame for the two classic false positives.** HSTS redirect loops and nosniff "breakage" are proxy and content-type bugs wearing a header costume; diagnosing them correctly in the rule stops the header from taking the fall.

3. **It makes omission visible by defining a baseline.** "Add headers when needed" produces nothing because need is never signaled; a named four-header floor turns absence into a checkable defect.

4. **It elevates shared-config header changes to disclosure.** One line in nginx affects every page served; requiring the summary to name it gets human eyes on exactly the changes that otherwise slide through in infrastructure diffs.

## Origin

A partner integration required embedding a banking portal's widget, and the assistant resolved the framing error by removing `X-Frame-Options` from the nginx config that served every page — including the funds-transfer screens. The narrow fix (`frame-ancestors` naming the partner's origin, on the widget route only) was never considered. A researcher later demonstrated a working clickjacking overlay on the transfer confirmation page; the disclosure timeline politely noted the header had been present in the git history, once.
