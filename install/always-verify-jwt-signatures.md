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
