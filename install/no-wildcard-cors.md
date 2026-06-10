### Never Fix CORS Errors With Wildcard Origins

NEVER respond to a CORS error by allowing all origins. CORS is an access-control policy, not a connectivity bug; the fix is naming the origins that should have access.

- Do not set `Access-Control-Allow-Origin: *` on any endpoint that serves user-specific data or sits behind authentication.
- Do not reflect the request's `Origin` header back unconditionally, and never combine reflection with `Access-Control-Allow-Credentials: true`. That grants every website on the internet credentialed access to the API.
- Configure an explicit allowlist instead: `cors({ origin: ["https://app.example.com", "https://staging.example.com"] })` or the framework equivalent. Add the dev origin (`http://localhost:3000`) explicitly for local work.
- Validate allowlist entries by exact match. Do not match with `startsWith` or a substring regex; `https://app.example.com.evil.io` passes both.
- `*` is acceptable only for truly public, unauthenticated, non-user-specific resources (public CDN assets, an open dataset), and say so in a comment when you use it.
- If the CORS error is happening because frontend and backend ports differ in dev, prefer a dev-server proxy over loosening the API's policy.

**Red flags that you're about to violate this:**
- "The wildcard unblocks development and we can tighten it before launch..."
- "Reflecting the origin is the standard workaround when you need credentials..."
- "It's an internal API, CORS doesn't really matter here..."
- "The mobile app doesn't send an Origin header anyway, so this is harmless..."
- "Every Stack Overflow answer for this error says to allow all origins..."
- "I'll match any subdomain of example.com with a regex to keep it flexible..."
