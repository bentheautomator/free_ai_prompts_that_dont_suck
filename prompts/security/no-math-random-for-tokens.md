---
title: Never Generate Tokens With Math.random
slug: no-math-random-for-tokens
category: security
tags: [universal, security, crypto]
works_with: all
severity: critical
one_liner: "AI using Math.random or random.random for tokens and reset codes"
---

# Never Generate Tokens With Math.random

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from using non-cryptographic randomness for anything security-sensitive.

**[Copy-paste ready version](../../install/no-math-random-for-tokens.md)** — just the instruction block, no explanation.

## The Problem

Asked to generate a password reset token, session ID, invite code, or API key, an AI will frequently produce some flavor of `Math.random().toString(36).substring(2)` or Python's `random.choices(string.ascii_letters, k=32)`. The output looks random. It is not, in the way that matters: these are PRNGs designed for speed and statistical uniformity, not unpredictability. `Math.random` (xorshift128+) can have its internal state recovered from a handful of observed outputs, after which an attacker computes every past and future "random" value your server will produce. Python's Mersenne Twister is recoverable from 624 outputs. Seeded with time, they're guessable with even less work.

The AI does this because the short, dependency-free snippet is overwhelmingly common in training data, where it generates DOM IDs and shuffle orders — places where predictability is harmless. The model pattern-matches "generate a random string" without registering that this particular string guards an account takeover. A predictable reset token means an attacker requests a reset for the victim's email and derives the token themselves.

Every runtime ships a CSPRNG. The secure version is the same number of lines.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It explains the actual attack.** "Use a CSPRNG" reads as pedantry until state recovery is named; once the AI has the mechanism in context, the cheap snippet stops looking equivalent.

2. **It enumerates what counts as security-sensitive.** AIs misfile invite codes, verification codes, and nonces as "not really credentials." The explicit list removes the categorization escape.

3. **It gives the drop-in replacement per language.** The insecure habit survives when the secure alternative requires research. `secrets.token_urlsafe(32)` is the same effort as the broken version.

4. **It blocks the hash-a-timestamp folk remedy.** This is the AI's favorite "more secure" upgrade that adds zero entropy, and it needs to be banned by name.

## Origin

A signup flow needed email verification, and the assistant generated six-digit codes with `random.randint` seeded implicitly at worker start. A researcher noticed codes from consecutive requests were correlated, reconstructed the Mersenne Twister state, and demonstrated verifying an arbitrary email without receiving the message. The fix was one import: `secrets` instead of `random`. The bounty payout cost more than the feature did.
