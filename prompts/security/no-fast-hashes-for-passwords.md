---
title: Never Hash Passwords With MD5 or SHA-256
slug: no-fast-hashes-for-passwords
category: security
tags: [universal, security, crypto]
works_with: all
severity: critical
one_liner: "AI storing passwords with fast hashes instead of bcrypt or argon2"
---

# Never Hash Passwords With MD5 or SHA-256

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from using general-purpose hash functions for password storage.

**[Copy-paste ready version](../../install/no-fast-hashes-for-passwords.md)** — just the instruction block, no explanation.

## The Problem

"Hash the password before storing it" sounds like a job for a hash function, so the AI writes `hashlib.sha256(password.encode()).hexdigest()` or `crypto.createHash('md5')`. Sometimes it even adds a salt and feels thorough. The result is a password table that a single consumer GPU can grind through at billions of guesses per second, because SHA-256 and MD5 were engineered to be fast, and fast is exactly the property a password hash must not have. Most human passwords fall to dictionary and rule-based attacks within hours at those speeds, salt or no salt.

This mistake is everywhere in training data: a decade of PHP tutorials, homework solutions, and toy auth examples that hash with MD5. The AI also conflates two distinct jobs — integrity hashing (checksums, content addressing, signatures) where speed is a feature, and password hashing, where the entire design goal is to be expensive and memory-hard so offline cracking doesn't scale. The vocabulary overlap ("just hash it") does the damage.

Dedicated password hashing functions — argon2id, bcrypt, scrypt — exist in every ecosystem, handle salting internally, and have tunable cost. Using them is a one-line difference.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Hash Passwords With MD5 or SHA-256

NEVER store passwords using general-purpose hash functions, even salted. ALWAYS use a dedicated password hashing algorithm: argon2id (preferred), bcrypt, or scrypt.

Fast hashes are designed for speed; password hashes are designed to make offline cracking expensive. A salted SHA-256 table cracks at GPU speed.

- Banned for passwords: MD5, SHA-1, SHA-256/512 (raw or with manual salt), a single HMAC, and any homemade "iterate the hash 100 times" loop.
- Use the ecosystem standard: `argon2` / `bcrypt` packages (Node), `argon2-cffi` or Django/Werkzeug's built-in hashers (Python), `golang.org/x/crypto/bcrypt` or `argon2` (Go), `password_hash()` (PHP), `BCryptPasswordEncoder` (Java/Spring). These generate and embed the salt for you; never build your own salting layer around them.
- Verify with the library's compare function (`bcrypt.compare`, `argon2.verify`, `password_verify`), never by hashing and string-comparing yourself.
- Mind bcrypt's 72-byte input truncation; do not "fix" it by pre-hashing with SHA-256 unless you understand the null-byte pitfalls — prefer argon2id instead.
- This applies to anything a human chose and typed: passwords, PINs, security answers, recovery phrases. (High-entropy machine-generated API tokens may use SHA-256 for lookup; humans-chose-it means slow hash.)
- If you encounter an existing fast-hash password table, do not just swap the algorithm for new signups; wrap or migrate existing hashes on next login and flag the exposure to the user.

**Red flags that you're about to violate this:**
- "SHA-256 is cryptographically secure, so it's secure for passwords..."
- "I added a per-user salt, which prevents cracking..."
- "bcrypt is an extra dependency; hashlib is in the standard library..."
- "This is an MVP, we'll upgrade the hashing when we have real users..."
- "I'll iterate SHA-256 a thousand times, that's basically PBKDF2..."
- "It's an internal tool, the password table will never leak..."

---

## Why It Works

1. **It splits the overloaded word "hash."** The AI's error is a vocabulary collision between integrity hashing and password hashing. Once the two jobs are distinguished in context, `hashlib` stops pattern-matching as correct.

2. **It preempts the salt defense.** "But I salted it" is the rationalization that makes fast hashes feel fixed. Stating that salted SHA-256 still cracks at GPU speed disarms the AI's strongest counterargument.

3. **It defines the boundary by who chose the secret.** "Human-chosen means slow hash" is a clean rule that correctly handles PINs, security answers, and the API-token exception without case-by-case judgment.

4. **It includes the migration path.** Without it, an AI told to fix legacy MD5 will silently rehash only new users, leaving the vulnerable rows in place while reporting the problem solved.

## Origin

A weekend-built auth system stored passwords as salted SHA-256 because the assistant noted it was "a secure, modern hash." Two years and forty thousand users later, a leaked database backup met a rules-based cracking rig; the majority of passwords were recovered inside a week and credential-stuffed against other services. The post-incident fix, argon2id via one library call, was indistinguishable in effort from the original mistake.
