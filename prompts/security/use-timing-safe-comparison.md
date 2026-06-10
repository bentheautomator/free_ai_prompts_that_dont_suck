---
title: Use Timing-Safe Comparison for Secrets
slug: use-timing-safe-comparison
category: security
tags: [universal, security, crypto]
works_with: all
severity: high
one_liner: "AI comparing tokens and signatures with == instead of constant-time checks"
---

# Use Timing-Safe Comparison for Secrets

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from validating tokens, API keys, and signatures with ordinary string equality.

**[Copy-paste ready version](../../install/use-timing-safe-comparison.md)** — just the instruction block, no explanation.

## The Problem

`if (providedToken === storedToken)` looks like the most innocent line in the codebase, and an AI will write it every single time it checks an API key, a webhook signature, or a password-reset token — because for ordinary strings, `===` is correct. For secrets, it's a side channel. Standard string comparison returns at the first mismatched byte, so a guess that gets the first character right takes measurably longer to reject than one that doesn't. An attacker who can send many requests and measure response times can recover a secret byte by byte, turning a 2^128 search into a few thousand requests per character. Network jitter raises the cost but statistical averaging pays it down, especially from a nearby vantage point.

This is one of the failures AI assistants will essentially never avoid on their own, because the vulnerable code is *identical* to correct code in every visible way — it compiles, passes every test, and matches a billion training examples. The fix functions exist precisely because humans have the same blind spot: `hmac.compare_digest`, `crypto.timingSafeEqual`, `hash_equals`, `ActiveSupport::SecurityUtils.secure_compare`. The rule's job is to define which comparisons are secret comparisons, because the AI won't classify them unprompted.

A related subtlety: comparing values derived from bcrypt/argon2 via library verify functions is already handled; this rule is about raw token and signature equality.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It classifies the comparisons for the model.** The AI can't act on "use constant-time comparison for secrets" without knowing which values count; the explicit list (webhooks, reset tokens, API keys) does the classification it would otherwise skip.

2. **It pairs each language with its function.** The vulnerable line is muscle memory; replacement only happens when the alternative token (`compare_digest`, `timingSafeEqual`) is in context at generation time.

3. **It handles the length-mismatch gotcha.** Node's `timingSafeEqual` throwing on unequal lengths is the friction that sends AIs back to `===`; addressing it head-on (compare hashes) removes the excuse.

4. **It pre-empts the entropy rationalization.** "The token is too random to brute-force" conflates search-space attacks with side-channel attacks; one sentence separating them closes the most intelligent-sounding objection.

## Origin

A payments webhook handler verified HMAC signatures with `expected === received`, written by an assistant that had correctly computed the HMAC two lines earlier. An attacker with a merchant account measured rejection timings from a same-region cloud instance, recovered enough signature bytes to forge events, and marked their own invoices paid. The fix was importing the comparison function that shipped with the same crypto module already in use; the postmortem's title was a single question mark.
