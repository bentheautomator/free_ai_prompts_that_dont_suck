### Never Return Stack Traces or Internal Errors to Clients

NEVER send internal error details in HTTP responses. Log the full error server-side with a correlation ID; return the ID and a generic message to the client.

Error responses are documentation for attackers: stack traces map your code, database errors map your schema, and distinct error messages become oracles.

- In catch blocks: `logger.error({err, requestId})` server-side, then respond `{ "error": "Internal error", "requestId": "..." }`. Never include `err.message`, `err.stack`, exception class names, SQL text, or file paths in the response body for unexpected errors.
- `err.message` is not safe just because it's short: driver and library messages embed table names, constraint names, hosts, and paths. Treat any message you didn't write as internal.
- Expected, user-fixable errors (validation failures, "name is required") should be specific — that's UX, not leakage. The line: messages you authored about THEIR input are fine; messages the system generated about YOUR internals are not.
- Auth flows must return identical errors and similar timing for "no such user" and "wrong password" ("Invalid email or password"), and registration/password-reset flows need the same care ("If that account exists, we sent an email").
- Set production config to suppress framework debug pages: Express error handler without stacktraces in prod, Django `DEBUG=False`, Rails `consider_all_requests_local = false`. Verify the production branch of the config, not just the default.
- GraphQL: disable verbose error extensions and stack traces in production (`includeStacktraceInErrorResponses: false`, mask internal errors); the default in several servers is chatty.
- 404 versus 403 on resources others own: prefer uniform 404 so existence isn't leaked.

**Red flags that you're about to violate this:**
- "Returning err.message makes debugging integration issues so much easier..."
- "The client team asked for descriptive errors..."
- "It's just the exception text, not a full stack trace..."
- "Telling users whether the email or the password was wrong is better UX..."
- "We'll turn off debug pages when we set up real prod config..."
- "Our API consumers are internal, they can see internals..."
