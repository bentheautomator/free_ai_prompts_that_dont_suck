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
