### Always Verify Webhook Signatures

NEVER process a webhook without verifying it came from the provider. Signature verification is part of the handler's skeleton, not a hardening step.

A webhook URL is public and guessable. Without verification it's an open API that anyone can use to mark orders paid, upgrade accounts, and feed your system fake events.

- Use the provider's SDK verification (`stripe.webhooks.constructEvent(rawBody, sigHeader, secret)`, GitHub's `X-Hub-Signature-256` HMAC check, Twilio's validator) before touching the payload. No SDK: compute the HMAC of the raw body with the shared secret and compare with a constant-time function, never `==`.
- Verification needs the raw bytes. Configure the route to receive them: `express.raw({type: 'application/json'})` on the webhook path before any JSON middleware, `request.get_data()` in Flask. If verification fails on valid-looking events, the body was parsed-and-reserialized upstream — fix the middleware order, do not remove the check.
- Reject on failure with 400 and log it; never "log a warning and process anyway."
- Check the timestamp where the scheme includes one (replay protection); make handlers idempotent on the event ID, since providers redeliver and attackers replay.
- Never decide trust from the payload's own fields (`"source": "stripe"`), the `User-Agent`, or IP ranges alone; those are optional defense in depth, not the control.
- Webhook secrets are credentials: from env/secret manager, distinct per environment, rotatable. Test-mode secrets differ from live — failing verification on test events usually means the wrong secret, not a broken library.
- These rules apply to every inbound automation callback: payment events, CI/CD hooks, messaging providers, OAuth/IdP back-channel calls, internal service hooks.

**Red flags that you're about to violate this:**
- "I'll get the event handling working first and add verification after..."
- "The signature check keeps failing, the library must be buggy, removing it for now..."
- "Nobody knows this URL, it's effectively private..."
- "The payload says it's from the provider, and it parses correctly..."
- "We can trust the provider's IP range instead of doing crypto..."
- "It's just a notification hook, worst case someone sends a fake notification..."
