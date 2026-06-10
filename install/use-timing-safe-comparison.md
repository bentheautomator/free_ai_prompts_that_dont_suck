### Use Timing-Safe Comparison for Secrets

NEVER compare secret values with `==`, `===`, or `.equals()`. Use the platform's constant-time comparison function.

Ordinary comparison exits at the first wrong byte, leaking how much of the guess was correct through response timing. Attackers recover secrets from that, byte by byte.

- Secret comparisons include: API keys, webhook HMAC signatures, password-reset and email-verification tokens, session tokens checked manually, OTP codes, signed-cookie MACs, and any `Authorization` header you validate yourself.
- Use: `hmac.compare_digest(a, b)` (Python), `crypto.timingSafeEqual(Buffer.from(a), Buffer.from(b))` (Node — equal lengths required, so compare hashes or check length separately without early-returning differently), `hash_equals()` (PHP), `subtle.ConstantTimeCompare` (Go), `MessageDigest.isEqual` (Java), `secure_compare` (Rails).
- Webhook signatures: compute the expected HMAC of the raw body, then constant-time-compare against the header value. Never `expected == provided`, and never compare truncated prefixes.
- For database-lookup tokens (reset links, API keys as primary key): the lookup itself can leak via timing too. Standard practice: store and query by SHA-256 of the token (also protects the table contents), or look up by a non-secret ID portion and constant-time-compare the secret portion.
- High-entropy random tokens make timing attacks slower, not invalid; apply the rule regardless of token strength, because rate limits and entropy estimates both have a way of being optimistic.
- Don't write your own "constant-time" loop with XOR unless no platform function exists; subtle compiler optimizations un-constant-time hand-rolled versions.

**Red flags that you're about to violate this:**
- "=== is how you compare strings, this is just a string..."
- "Timing attacks are theoretical over the public internet..."
- "The token is 256 bits of randomness, timing leaks don't matter..."
- "timingSafeEqual throws on length mismatch, regular equality is more robust..."
- "It's an internal webhook, the sender is trusted..."
- "I'll optimize this comparison later if it's actually a problem..."
