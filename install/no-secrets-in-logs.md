### Never Log Credentials or Full Request Bodies

NEVER log secrets, and never log whole request/response objects on endpoints that can carry them. Log specific, named, non-sensitive fields instead.

Logs have weaker access control and longer retention than your database. A token in a log is a token leaked.

- Never log: passwords, tokens (bearer, refresh, session, CSRF), API keys, `Authorization`/`Cookie`/`Set-Cookie` headers, security answers, OTP codes, private keys, or full card numbers.
- Do not dump containers that might hold them: `req.body`, `req.headers`, `request.POST`, config objects, env (`process.env`, `os.environ`), caught exception objects from auth libraries, or axios/fetch error objects (which embed the request, headers included).
- Log selectively: `logger.info("login failed", {username, reason})`, not the body. If a sensitive value must be referenced, log a redacted form (`tok_...last4`) or a hash, and say which.
- On auth endpoints specifically, the password field is present in the body by definition. Never add body logging there, even at debug level; debug level runs in prod more often than anyone admits.
- When adding diagnostic logging during a session, list every log line you added in your summary so they can be reviewed and removed.
- If the project has a redaction/allowlist mechanism in its logger, route new logging through it instead of around it.

**Red flags that you're about to violate this:**
- "I'll log the whole request just while we track this down..."
- "It's debug level, it won't show up in production..."
- "Logging the headers will show us if the token is being sent..."
- "Our logs are internal, only engineers can read them..."
- "I'll dump the config object to see what's actually loaded..."
- "One verbose log line is the fastest way to see everything at once..."
