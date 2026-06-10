### Use Obvious Placeholders in Doc Examples

NEVER put realistic-looking secrets, credentials, emails, or identifiers in documentation examples. Every example value must be unmistakably fake at a glance and impossible to mistake for working configuration.

The problem: realistic example values get copied into real configs, flagged by secret scanners, and occasionally collide with actual people's data. Realism in example values is a bug, not polish.

Rules:
- Secrets and keys: use clearly-labeled placeholders in the project's existing convention, e.g. `<your-api-key>` or `YOUR_API_KEY`. Never generate a string matching a real provider's key format (`sk_live_...`, `AKIA...`, `ghp_...`, JWT-shaped blobs)
- Emails and domains: use reserved ones only: `user@example.com`, `example.org`, `*.example.net`. Never `@gmail.com` addresses or plausible company domains; those resolve to real inboxes and real sites
- IPs and hostnames: use documentation ranges (`192.0.2.x`, `198.51.100.x`, `203.0.113.x`) and `localhost`/`example.com` derivatives, not addresses that route
- IDs: make them readably fake (`usr_0000example`, `order_TEST123`), not statistically plausible
- Mark substitution points consistently: if the doc set uses `<angle-brackets>`, use those everywhere; mixing conventions makes some placeholders look literal
- Where a reader could plausibly paste the placeholder itself, add the one-line note: "replace `<your-api-key>` with the key from your dashboard"
- Never copy real values from the repo, env files, or logs into docs "as examples," even partially redacted

**Red flags that you're about to violate this:**
- "A realistic key makes the example clearer..."
- "I'll generate a random string in the right format..."
- "This email is obviously made up..." (it's somebody's)
- "I'll use the value from the .env file but change a few characters..."
- "Real-looking IDs make the response example believable..."
- "Nobody would actually copy-paste the placeholder..."
