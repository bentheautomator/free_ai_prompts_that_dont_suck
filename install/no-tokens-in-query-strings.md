### Never Put Tokens or Keys in URL Query Strings

NEVER carry long-lived credentials in URLs. API keys go in the `Authorization` header; session state goes in cookies or headers; one-time links get short expiry and single-use enforcement.

URLs are copied everywhere by default: access logs, proxy logs, Referer headers, browser history, analytics. A key in a query string is a key distributed to every system that ever sees the request line.

- API authentication: `Authorization: Bearer <token>` (or the provider's header). Do not design `?api_key=` parameters into new endpoints, and do not use a provider's legacy query-param auth when a header form exists. Examples and docs you write follow the same rule.
- Never place session tokens, JWTs, or OAuth access tokens in query strings or in redirect URL parameters. For browser flows, use the authorization-code flow where tokens move in POST bodies and cookies, not the URL bar.
- Links that must carry a secret (password reset, magic login): single-use tokens, expiring in minutes-to-hours, invalidated on use and on password change, with the landing page immediately exchanging the token for a session and scrubbing it from the address bar.
- Mint presigned URLs (S3-style) with the shortest workable expiry, scoped to one object and method; an unexpiring signed URL is a permanent public link in disguise.
- Defense in depth for pages that ever see sensitive URLs: `Referrer-Policy: strict-origin-when-cross-origin` or stricter, and configure logging/telemetry to redact known token parameters.
- GET-with-body-in-query designs ("?password=" on a login form because GET was easier) are the same bug with less dignity; credentials ride in POST bodies.

**Red flags that you're about to violate this:**
- "Query-param auth means users can test the API right in the browser..."
- "The link token is random and unguessable, the URL is as good as private..."
- "Our logs are internal, who cares if the key appears there..."
- "I'll give the presigned URL a one-year expiry so customer links never break..."
- "The provider's docs show api_key as a parameter, I'll match their example..."
- "It's HTTPS, the URL is encrypted anyway..."
