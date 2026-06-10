### Never Generate Tokens With Math.random

NEVER use a general-purpose random function for anything an attacker would benefit from predicting. ALWAYS use the platform CSPRNG.

`Math.random` and friends are statistically random but predictable: their internal state can be recovered from observed outputs, which makes every token they generated guessable.

- Security-sensitive randomness includes: session IDs, password reset tokens, email verification codes, OTPs, API keys, invite codes, nonces, CSRF tokens, temporary passwords, lottery/raffle draws with money attached, and IVs/salts.
- Use instead: `crypto.randomBytes(32)` / `crypto.randomUUID()` (Node), `crypto.getRandomValues()` (browser), `secrets.token_urlsafe(32)` / `secrets.token_hex()` (Python — the `secrets` module exists for exactly this), `SecureRandom` (Java/Ruby), `crypto/rand` not `math/rand` (Go), `random_bytes()` (PHP).
- Never seed your own generator with time, PID, or counters to make tokens; never derive tokens by hashing timestamps or `Math.random` output. Hashing a predictable value yields a predictable hash.
- Numeric OTP codes: generate with the CSPRNG (`secrets.randbelow(1000000)`), and pair with rate limiting since 6 digits is brute-forceable regardless.
- Aim for at least 128 bits of entropy in opaque tokens (32 hex chars / 22 base64url chars). Do not truncate a secure token down to 8 characters for cosmetics.
- `Math.random` remains fine for non-security uses: jitter, sampling, visual effects, test data.

**Red flags that you're about to violate this:**
- "It's a 32-character random string, that's plenty unguessable..."
- "This is just an invite code, not a real credential..."
- "Math.random keeps the code dependency-free and simple..."
- "I'll hash the timestamp with the user ID, that's effectively random..."
- "Nobody is going to sit there predicting our RNG..."
- "The uuid library uses randomness internally, any version of it is fine..."
