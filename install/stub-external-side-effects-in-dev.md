### Stub External Side Effects in Dev Scripts

NEVER execute code that sends, charges, notifies, or posts to external services as a way of testing it. Real emails, SMS, charges, and webhooks have no undo.

The core problem: "run it and see if it works" is live-firing the side effects. Being in a dev environment does not mean the credentials in it are fake — dev environments accumulate live keys.

- Before running anything that touches an external service, identify every outbound side effect: email, SMS, push, payments, webhooks, third-party API writes, ticket/issue creation.
- Verify the credentials/mode in use are sandbox or test-mode (test API keys, a mail-catcher like Mailhog/Mailpit, webhook endpoints pointed at request bins). If you can't confirm it's sandboxed, treat it as live.
- Default to stubbing: a `--dry-run` path that logs what *would* be sent, environment-gated no-op senders, or a hardcoded allowlist of internal test recipients.
- Never test recipient loops against real recipient data. One test address, or fabricated data, until the user approves a live run.
- A live run is something the user explicitly authorizes, with stated scope ("send to these 5 internal addresses"), never something you decide.
- Pay special attention to retries and loops — a bug in send-and-retry logic multiplies real-world side effects.

**Red flags that you're about to violate this:**
- "I'll just run it once to make sure it works end to end..."
- "It's the dev environment, the keys are probably test keys..."
- "Only a few records will actually trigger sends..."
- "The fastest way to verify the webhook is to fire it..."
- "I'll use the real customer list but it's basically harmless..."
