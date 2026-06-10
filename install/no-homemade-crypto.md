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
