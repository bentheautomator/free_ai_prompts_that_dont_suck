---
title: Never Redirect to User-Supplied URLs
slug: no-open-redirects
category: security
tags: [universal, security]
works_with: all
severity: high
one_liner: "AI redirecting to a next or returnUrl parameter without validation"
---

# Never Redirect to User-Supplied URLs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents open redirects: login flows and link handlers that forward users to attacker-chosen destinations.

**[Copy-paste ready version](../../install/no-open-redirects.md)** — just the instruction block, no explanation.

## The Problem

Post-login redirects are a standard UX requirement: send the user back to where they were. The AI implements it as `res.redirect(req.query.returnUrl)` or `return redirect(request.args.get("next"))`, and now your trusted domain forwards anyone anywhere. The attack writes itself: `https://yourapp.com/login?next=https://yourapp-login.evil.com` arrives in a phishing email, the victim sees your legitimate domain, authenticates on your real login page, and is then seamlessly delivered to a pixel-perfect fake that harvests whatever comes next. Your domain's reputation is doing the attacker's work.

Open redirects get dismissed as low severity until they're the link-trust laundering step in a phishing campaign, the bounce that steals an OAuth code via a redirect chain, or the bypass for a URL allowlist somewhere else. AI assistants create them readily because the naive implementation is the obvious one, and their first attempts at validation are reliably bypassable: checking the URL `startsWith("/")` (protocol-relative `//evil.com` passes), checking it contains your domain (`evil.com/yourapp.com` or `yourapp.com.evil.com` pass), or blocklisting `http://` (whitespace, backslashes, and `https:/\` tricks pass).

The robust patterns are boring: relative paths only, or an allowlist of named destinations.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Redirect to User-Supplied URLs

NEVER pass a user-controlled value to a redirect without strict validation. Prefer designs where the client never supplies a URL at all.

An open redirect turns your trusted domain into a phishing launcher: victims verify YOUR domain, log in on YOUR page, and land on the attacker's.

- Best: don't accept URLs. Accept a key into a server-side map of named destinations (`?dest=dashboard`), or store the intended destination in the session before redirecting to login.
- If a path parameter is unavoidable, enforce all of: it starts with exactly one `/` (reject `//` and `/\`, which browsers treat as protocol-relative), it contains no scheme or backslash, and then resolve it against your own origin. In frameworks, use the built-in helper where one exists (Django's `url_has_allowed_host_and_scheme`, Rails' `redirect_to ... allow_other_host: false`) instead of hand-rolling.
- Never validate with substring or prefix string checks: `url.includes("myapp.com")`, `startsWith("https://myapp.com")` (defeated by `https://myapp.com.evil.io`), or regexes you wrote at 4pm. Parse with the URL parser and compare the origin exactly.
- The same rule covers cousins: `window.location = userValue` in frontend code, `Location` headers built from input, OAuth `redirect_uri` handling (exact-match against registered URIs, never prefix-match), and "link out" interstitial endpoints.
- `javascript:` and `data:` schemes must never survive validation; rejecting everything that isn't a same-origin path handles this automatically.
- If product genuinely requires redirecting off-site (partner links), use an explicit allowlist of full origins and show an interstitial; say so in the code with a comment.

**Red flags that you're about to violate this:**
- "It's just a post-login convenience parameter, who would tamper with it..."
- "I check that the URL starts with a slash, so it stays on our site..."
- "The value contains our domain name, that proves it's ours..."
- "Open redirects are low severity anyway, not worth the ceremony..."
- "OAuth needs flexible redirect URIs for all our environments..."
- "The frontend builds this URL, so it's not really user input..."

---

## Why It Works

1. **It leads with the no-URL designs.** Session-stored destinations and named keys eliminate the input rather than validating it, and the AI will use them if they're presented as the default rather than the exotic option.

2. **It enumerates the bypasses for the validations AIs actually write.** `//`, backslashes, and substring-match domains are precisely the second-draft "fixes" a model produces; pre-empting them prevents the false sense of done.

3. **It connects the bug to its real impact.** Models rank open redirects as trivial and act accordingly; the phishing-laundering framing recalibrates the severity that drives effort.

4. **It pulls OAuth redirect_uri into scope.** The highest-stakes instance of this bug class hides inside auth flows where prefix-matching feels reasonable; exact-match-against-registered is stated as the rule.

## Origin

A login page accepted a `next` parameter, validated as "must start with a slash" by the assistant that built it. A phishing campaign used `next=//account-verify.example-update.com`, which browsers happily treated as protocol-relative and followed off-site after a successful, real login. Several hundred employees re-entered credentials on the fake "session expired" page that followed. The patched validator was the framework's own helper, available the whole time, called with `allowed_hosts={request.get_host()}`.
