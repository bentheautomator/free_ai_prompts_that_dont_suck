---
title: Never Roll Your Own Crypto
slug: no-homemade-crypto
category: security
tags: [universal, security, crypto]
works_with: all
severity: critical
one_liner: "AI inventing XOR ciphers and custom encryption instead of using a library"
---

# Never Roll Your Own Crypto

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from hand-writing encryption schemes or misusing crypto primitives in homemade constructions.

**[Copy-paste ready version](../../install/no-homemade-crypto.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to "encrypt this field before storing it" and you might get a real library call. You might also get a XOR loop against a repeating key, base64 dressed up as encryption, AES in ECB mode (the penguin mode), AES-CBC with a static IV, or a bespoke scheme that encrypts with a key derived by MD5-ing a password. The code runs, the output looks like ciphertext, and every one of these is breakable by a motivated undergraduate. AI assistants are uniquely dangerous here because they produce confident, working-looking crypto code on demand, complete with reassuring comments.

The failure has two flavors. The first is inventing a scheme outright, which happens when the AI wants zero dependencies or the user said "simple." The second is misassembling real primitives: right cipher, wrong mode; encryption without authentication, leaving ciphertexts malleable; reused nonces in GCM, which doesn't just weaken the scheme but shatters it; keys derived from passwords without a real KDF. Both flavors pass tests, because tests check that decrypt(encrypt(x)) == x, which is true of ROT13 too.

High-level libraries exist precisely because composing primitives correctly is a specialist skill. The AI should be gluing, not designing.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Roll Your Own Crypto

NEVER design, implement, or modify a cryptographic scheme. ALWAYS use a high-level, audited library and its documented recommended usage.

Crypto code that runs and round-trips correctly can still be trivially breakable; tests cannot tell the difference, and neither can code review by non-specialists.

- Never write: XOR "encryption," custom cipher loops, base64/hex as a privacy layer, homemade key exchange, custom token-signing schemes, or your own padding/MAC logic.
- Use high-level APIs that make the choices for you: libsodium/NaCl (`secretbox`, `sealed box`), Python `cryptography`'s Fernet, Go `crypto/nacl`, age for files. Reach for raw primitives only when the high-level API genuinely cannot do the job, and say why.
- If primitives are unavoidable: AES-256-GCM or ChaCha20-Poly1305 (authenticated encryption only, never ECB, never unauthenticated CBC), a unique random nonce per encryption stored alongside the ciphertext, keys from a real KDF (argon2id, scrypt, PBKDF2 with high iterations) when derived from passwords.
- Never hardcode, reuse, or zero-fill IVs/nonces. A repeated GCM nonce under the same key is a catastrophic break, not a weakness.
- Do not "fix" or "optimize" existing crypto code you encounter; flag it for specialist review instead. Removing one confusing line can remove the authentication.
- Signing/verification (JWTs, webhooks, cookies): use the library's verify function. Never compare or reconstruct signatures manually.

**Red flags that you're about to violate this:**
- "A simple XOR with a secret key is enough obfuscation for this..."
- "I'll avoid adding a dependency by implementing the cipher inline..."
- "ECB is fine here because each record is a single block anyway..."
- "We can use a fixed IV since it's the same service encrypting and decrypting..."
- "MD5 of the passphrase gives us a 128-bit key, which is plenty..."
- "I'll simplify this crypto helper, half of these steps look redundant..."

---

## Why It Works

1. **It separates gluing from designing.** The AI is good at calling Fernet and terrible at knowing why CBC-without-MAC fails. Restricting it to high-level APIs keeps it inside its competence.

2. **It names the specific landmines.** ECB, static IVs, nonce reuse, password-as-key: these are the four mistakes that account for most AI-generated crypto failures, and each is individually banned with the correct alternative.

3. **It blocks "improvement" of existing crypto.** Refactoring is where working crypto quietly loses its authentication step or its random IV. Treating existing crypto as do-not-touch prevents regression by cleanup.

4. **It pre-defines the round-trip-test fallacy.** Pointing out that ROT13 passes the same test removes the AI's main evidence that its homemade scheme "works."

## Origin

Asked to encrypt stored OAuth refresh tokens "without pulling in heavy dependencies," an assistant wrote a tidy AES-CBC helper with the IV hardcoded as sixteen zero bytes and no MAC. It passed review because the code was clean and the tests passed. A later audit found that identical token prefixes produced identical ciphertext prefixes across the entire table, and that any ciphertext could be bit-flipped predictably. Every token had to be revoked and the table re-encrypted with libsodium, which had been one `npm install` away the whole time.
