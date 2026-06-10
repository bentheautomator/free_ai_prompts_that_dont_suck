---
title: Always Verify JWT Signatures
slug: always-verify-jwt-signatures
category: security
tags: [universal, security, auth]
works_with: all
severity: critical
one_liner: "AI decoding JWTs without verifying, or accepting alg none"
---

# Always Verify JWT Signatures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from trusting JWT claims without cryptographic verification.

**[Copy-paste ready version](../../install/always-verify-jwt-signatures.md)** — just the instruction block, no explanation.

## The Problem

A JWT is two base64 blobs of attacker-editable text plus a signature, and only the signature makes any of it true. AI assistants regularly write code that reads the blobs and skips the math: `jwt.decode(token, options={"verify_signature": False})` in PyJWT (often copied from a debugging snippet), `jwt.decode(token)` from libraries where `decode` means "parse, don't verify" while `verify` is a different function, or hand-rolled `JSON.parse(atob(token.split('.')[1]))` to "just grab the user ID real quick." Every one of these means anyone can mint a token claiming to be anyone.

The library landscape actively invites this. Some `decode` functions verify by default, some never verify, some verify only if you pass the key, and the AI's training data mixes all of them, so it produces plausible calls with the wrong semantics for the library at hand. Then there are the configuration failures: accepting whatever `alg` the token header declares (hello, `alg: none`, and the HS256/RS256 confusion where the public key becomes an HMAC secret), skipping expiry checks because tests kept failing with expired fixtures, or not pinning the expected issuer and audience so a token minted for one service unlocks another.

One rule covers all of it: nothing inside a JWT exists until the signature, algorithm, expiry, and audience have been checked.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Always Verify JWT Signatures

NEVER read claims from a JWT before verifying it. A decoded-but-unverified JWT is attacker input with nice formatting.

- Always call the library's verifying API with the key and an explicit algorithm list: `jwt.decode(token, key, algorithms=["RS256"], audience=..., issuer=...)` (PyJWT), `jwt.verify(token, key, { algorithms: ["RS256"] })` (Node jsonwebtoken — `jwt.decode()` there does NOT verify).
- Never write `verify_signature: False`, `{ verify: false }`, or manual `JSON.parse(atob(...))` / `base64`-split parsing of the payload in server code, even "just to read the user ID." The user ID is exactly the claim attackers forge.
- Pin the algorithm server-side. Never derive it from the token's own header, never include `none`, and never allow both HMAC and RSA families together (RS256-to-HS256 confusion lets the public key sign tokens).
- Do not disable expiry (`verify_exp: False`) to fix failing tests; generate fresh test tokens instead. Validate `aud` and `iss` so tokens from other services or tenants don't cross over.
- Secrets: HMAC keys must be long random values from configuration, never a literal like `"secret"` or the app name. For third-party IdPs, fetch keys via JWKS with the `kid` header, through the library's supported mechanism.
- Client-side display code may decode without verifying (it has no key), but must never make security decisions from claims; the server re-verifies on every request.

**Red flags that you're about to violate this:**
- "I just need the user ID out of the token, full verification is overkill here..."
- "decode() is simpler than verify() and the gateway already checked it..."
- "Tests keep failing on expired tokens, I'll turn off the exp check..."
- "I'll take the algorithm from the token header to support multiple key types..."
- "It's a microservice behind the load balancer, tokens are pre-trusted..."
- "Using 'secret' as the key is fine until we wire up real config..."

---

## Why It Works

1. **It corrects the decode/verify vocabulary trap.** The AI's most common failure is calling a function whose name sounds sufficient. Stating per-library which call verifies removes the ambiguity the bug lives in.

2. **It bans payload-parsing shortcuts by their exact shape.** `JSON.parse(atob(...))` doesn't look like an auth decision, it looks like data access. Naming it reclassifies it.

3. **It makes algorithm pinning non-negotiable.** `alg: none` and HS/RS confusion are attacks on configuration defaults; an explicit allowlist requirement turns both into impossible states.

4. **It addresses the "gateway already verified it" assumption.** Internal services skipping verification is the deferred version of the same bug, and it fails the day any other path reaches the service.

## Origin

A reporting service needed the tenant ID from incoming tokens, and the assistant grabbed it with a base64 split "since the API gateway validates tokens upstream." A later infrastructure change exposed the service on an internal port reachable from a less-trusted network segment, where a crafted token with an edited tenant claim pulled another customer's reports. Verification had been a one-argument change in a library already imported in the same file.
