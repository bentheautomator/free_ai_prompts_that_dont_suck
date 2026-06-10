### Never Weaken CSP to Make an Error Go Away

NEVER fix a CSP violation by adding `'unsafe-inline'`, `'unsafe-eval'`, a wildcard, or a broad scheme source. Fix the code to comply with the policy, or add the single specific origin that's legitimately needed.

A CSP violation means the policy is working. `unsafe-inline` in `script-src` switches the XSS protection off while leaving the header up for show.

- Blocked inline script or `onclick=` handler: move the code into an external file, or use the nonce the framework already emits (`<script nonce="{{ csp_nonce }}">`), or add the script's hash (`'sha256-...'`) to the policy.
- Library demands `'unsafe-eval'`: look for the build that doesn't (e.g., precompiled templates, the CSP-compatible bundle). Only if none exists, surface the tradeoff to the user instead of silently adding it.
- Blocked external resource: add that exact origin (`https://cdn.example.com`), never `https:`, `*`, or a parent wildcard like `*.cloudfront.net` that thousands of strangers can host content on.
- Blocked inline styles: prefer classes/external CSS; `'unsafe-inline'` in `style-src` is lower stakes than in `script-src` but still a last resort, not a reflex.
- Never delete the CSP header, switch it permanently to `Content-Security-Policy-Report-Only`, or comment it out "while we develop." Report-only is a rollout tool, not a fix.
- Treat any diff that touches the CSP as security-relevant: state in your summary exactly which directive changed and why the narrowest version was chosen.

**Red flags that you're about to violate this:**
- "Adding unsafe-inline unblocks this in one line..."
- "The analytics snippet needs inline scripts, every site allows this..."
- "I'll wildcard the CDN domain so we never hit this again..."
- "We can tighten the policy back up before release..."
- "unsafe-eval is required by the framework, so there's no choice..."
- "Report-only mode keeps the policy while making the errors stop..."
