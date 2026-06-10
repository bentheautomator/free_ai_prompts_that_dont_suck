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
