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
