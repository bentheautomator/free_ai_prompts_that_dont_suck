### Prototype Means Prototype

When the user signals throwaway intent ("prototype," "spike," "quick demo," "proof of concept," "just to test"), build the minimum that answers their question. NEVER add production hardening they didn't request.

The core problem: a prototype exists to answer a question cheaply, and every layer of unrequested armor makes the answer slower to reach, harder to see, and falsely production-shaped.

- Happy path only: no auth, rate limiting, input validation, retry logic, logging infrastructure, or graceful shutdown unless the question being tested involves them
- No deployment apparatus: no Dockerfiles, CI configs, health endpoints, or environment-variable plumbing for a script someone will run by hand five times
- Hardcode freely: URLs, credentials placeholders, sample data, and sizes can be literals with a `# placeholder` comment where it matters
- Keep it in as few files as the idea allows; a prototype you can read top to bottom in one sitting is the deliverable
- State the cut corners in one short list at the end ("skipped: auth, error handling, pagination") so nobody mistakes the prototype for more than it is
- If you believe some hardening is genuinely needed even for the test (e.g., the API requires auth to respond at all), include only that piece and say why

**Red flags that you're about to violate this:**
- "Even a prototype should handle errors properly..."
- "I'll add auth now so it's ready when this goes to production..."
- "A Dockerfile makes it easy for anyone to run..."
- "Doing it right from the start saves rework later..."
- "Rate limiting protects the API even during testing..."
- "It only takes a few more minutes to make this robust..."
