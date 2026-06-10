---
title: Set Secure Flags on Session Cookies
slug: set-secure-cookie-flags
category: security
tags: [universal, security, auth]
works_with: all
severity: high
one_liner: "AI creating session cookies without HttpOnly, Secure, or SameSite"
---

# Set Secure Flags on Session Cookies

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from issuing auth cookies that JavaScript can read and plaintext connections can carry.

**[Copy-paste ready version](../../install/set-secure-cookie-flags.md)** — just the instruction block, no explanation.

## The Problem

`res.cookie("session", token)` — one line, works immediately, and ships with every protection turned off. Without `HttpOnly`, any XSS anywhere on the site (including in that third-party widget you didn't write) can read the session cookie and export it. Without `Secure`, the cookie rides along on any plaintext HTTP request — and an attacker on the network can *induce* one, since the browser will attach the cookie to `http://yourapp.com/favicon.ico` requests it's tricked into making. Without `SameSite`, cross-site requests carry it, re-opening the CSRF door. The flags exist because each of these attacks is routine; the default-off behavior exists because of backwards compatibility, not because default-off is ever what you want for auth.

AI assistants emit the bare version because the minimal API call is the most common form in training data, and because the missing flags cause zero visible difference in development — the cookie sets, the session works, the feature demos. The related failures travel in a pack: setting `secure: false` permanently because localhost is HTTP, lifetimes of a year on sensitive sessions, tokens in `localStorage` instead of cookies specifically to avoid thinking about cookie flags (trading CSRF risk for full XSS-theft exposure), and session fixation — not rotating the session ID at login.

This is configuration, not architecture. The secure version is the same line with an options object.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Set Secure Flags on Session Cookies

ALWAYS set `HttpOnly`, `Secure`, and `SameSite` on cookies that carry authentication. The bare `res.cookie(name, value)` form is not acceptable for session material.

Each missing flag is a live attack class: no HttpOnly means any XSS steals the session; no Secure means networks see it; no SameSite means cross-site requests use it.

- Default for session/auth cookies: `{ httpOnly: true, secure: true, sameSite: "lax", path: "/" }` (Express), `SESSION_COOKIE_HTTPONLY/SECURE/SAMESITE` (Django), `cookie SameSite=Lax; Secure; HttpOnly` however your stack spells it. Use `strict` where the UX tolerates it; use `none` only with `secure: true` and a documented cross-site requirement.
- For local HTTP development, gate `secure` on environment (`secure: process.env.NODE_ENV === "production"`), never delete it. Better: run dev on https or localhost, which browsers treat as secure context.
- Set sensible lifetimes: hours-to-days for auth, not a year to "avoid annoying re-logins." Long-lived "remember me" belongs in a separate rotating token with server-side revocation.
- Rotate the session identifier on login and privilege change (`req.session.regenerate`; framework login helpers do this — don't bypass them), and invalidate server-side on logout, not just by clearing the browser cookie.
- Add the `__Host-` prefix to the cookie name where supported; it makes the browser enforce Secure, no Domain attribute, and `path=/`.
- Do not move tokens to `localStorage`/`sessionStorage` to sidestep cookie configuration: storage is readable by any script on the page, which converts every XSS into full token theft. HttpOnly cookies plus CSRF protection remains the default pattern for browser sessions.
- Cookies that aren't auth (preferences, analytics) may relax HttpOnly when client JS genuinely needs to read them; say which cookie and why in a comment.

**Red flags that you're about to violate this:**
- "The bare cookie call works fine, flags are polish for later..."
- "secure: true breaks localhost, so I'll leave it off everywhere..."
- "localStorage is simpler than dealing with cookie attributes..."
- "A one-year expiry saves users from re-logging in..."
- "SameSite defaults are good enough in modern browsers..."
- "It's an internal app on the office network, transport theft isn't realistic..."

---

## Why It Works

1. **It attaches an attack to each flag.** A list of attributes reads as boilerplate to skip; "no HttpOnly means XSS steals sessions" gives each flag a consequence the model weighs.

2. **It solves the localhost conflict properly.** `secure: false` everywhere is the AI's standard resolution of the dev-HTTP problem; the environment-gated pattern resolves the same friction without disarming production.

3. **It blocks the localStorage escape route.** Models propose storage APIs specifically to avoid cookie complexity; naming the XSS-theft tradeoff keeps the avoidance from masquerading as a simplification.

4. **It bundles rotation and server-side logout.** Fixation and irrevocable sessions are the adjacent failures that flag-focused rules miss, and they're cheapest to fix in the same code the AI is already touching.

## Origin

A dashboard's session cookie shipped flagless from a scaffold, and stayed that way because everything worked. A year later, an XSS in a marketing-site widget sharing the parent domain read session cookies from logged-in users and replayed them; the sessions were also configured to live for six months, so stolen ones kept working long after the XSS was patched. Three cookie attributes and a sane expiry, present from day one, would have reduced the incident to a blog post about the widget.
