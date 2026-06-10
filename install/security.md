### Always Check Object Ownership Before Access

NEVER fetch, update, or delete a record by client-supplied ID alone. Every query for a user-scoped resource must include the requester's identity (or an explicit permission check) in the lookup itself.

Authentication says who they are. It says nothing about whose invoice that is. Those are different checks, and the second one is the one AIs skip.

- Scope queries at the database: `Invoice.findOne({ _id: id, userId: req.user.id })`, `WHERE id = $1 AND owner_id = $2`, `current_user.invoices.find(params[:id])`. A miss returns 404, identical to "doesn't exist," so existence isn't leaked.
- Apply it to every verb. Read-only IDOR leaks data; unchecked PUT/PATCH/DELETE lets users edit and destroy other people's records. Update/delete handlers need the same scoped lookup, not a trailing `if` after an unscoped fetch.
- Check the whole chain on nested routes: `/orgs/:orgId/projects/:projectId/files/:fileId` requires verifying the file belongs to the project, the project to the org, and the requester to the org. Checking only the leaf lets attackers graft valid IDs onto other tenants.
- Never accept the owner from the request: `userId` in the body or query is attacker input. Take identity from the verified session/token only.
- UUIDs, hashids, and "unguessable" identifiers are not authorization; they leak through logs, referrers, exports, and adjacent endpoints. Do the check regardless of key format.
- Shared-access models (collaborators, teams) replace the ownership equality with a membership/permission lookup, still enforced server-side per request, and centralized in one helper or policy layer rather than re-improvised per handler.
- For list endpoints, filter by owner in the query itself, never fetch-all-then-filter in application code or, worse, the client.

**Red flags that you're about to violate this:**
- "The route already requires login, so it's protected..."
- "IDs are UUIDs, no one can guess another user's..."
- "The frontend only ever links to your own records anyway..."
- "I'll fetch the record first and we can add ownership filtering later..."
- "This is the admin codebase, scoping would just get in the way..."
- "The parent resource was checked upstream, the child must be fine..."

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

### Disable External Entities When Parsing XML

ALWAYS configure XML parsers handling untrusted input to forbid DTDs and external entities. In ecosystems where the parser is unsafe by default, the hardening flags are mandatory boilerplate, not optional.

An entity-resolving parser is a file-reader and URL-fetcher that takes instructions from the document it's parsing.

- Java: on `DocumentBuilderFactory`/`SAXParserFactory`, set `factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)` (the strongest single switch), plus disable `external-general-entities`/`external-parameter-entities`, and `setXIncludeAware(false)`, `setExpandEntityReferences(false)`. Same treatment for `XMLInputFactory` (`SUPPORT_DTD: false`) and transformers (`ACCESS_EXTERNAL_DTD`/`ACCESS_EXTERNAL_STYLESHEET` to "").
- Python: prefer `defusedxml` for untrusted XML; with lxml, use `etree.XMLParser(resolve_entities=False, no_network=True)` and avoid DTD validation of untrusted docs.
- PHP: ensure libxml >= 2.9 or call `libxml_disable_entity_loader(true)` on older versions; don't pass `LIBXML_NOENT` (it *enables* substitution, despite the name).
- .NET: `XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit }`; do not assign an `XmlResolver` to re-enable fetching.
- Treat as untrusted XML: uploaded files including SVG and Office formats (zipped XML), SAML responses, SOAP bodies, RSS/Atom feeds, sitemaps, and any third-party API response in XML.
- If a parse error mentions undefined entities or DOCTYPE, the fix is rejecting the document or stripping the DTD, never enabling entity resolution to make the document parse.
- Where the data doesn't have to be XML at all, prefer JSON and delete the problem.

**Red flags that you're about to violate this:**
- "The default parser configuration is presumably safe in a modern library..."
- "LIBXML_NOENT sounds like it disables entities, I'll add it..."
- "This XML comes from a partner's system, not from attackers..."
- "The parse fails on the DOCTYPE, so I'll enable DTD processing..."
- "It's just an SVG thumbnail pipeline, not an XML API..."
- "Adding five feature flags for one parse call is overkill..."

### Keep Security Headers On

ALWAYS include baseline security headers on new web services, and NEVER fix an embedding or rendering problem by deleting a header globally. Narrow the policy to the case that needs it.

Missing headers are silent: nothing breaks, nothing warns, and each absence is a standing invitation (clickjacking, MIME confusion, protocol downgrade).

- Baseline for any new HTTP service: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` (or CSP `frame-ancestors 'none'`), `Strict-Transport-Security: max-age=31536000; includeSubDomains` on HTTPS sites, `Referrer-Policy: strict-origin-when-cross-origin`. Use the packaged bundle where it exists — `helmet()` in Express, `django.middleware.security` settings, framework defaults — rather than hand-maintaining.
- Legitimate embedding need (partner iframe, embed product): replace DENY with CSP `frame-ancestors https://partner.example.com` listing the exact origins. Do not delete the header, and do not set `ALLOWALL`-style values.
- One Helmet/middleware header causing friction: disable that single header by option (`helmet({ frameguard: false })` plus the narrowed replacement), never the whole bundle.
- HSTS issues behind proxies are almost always `X-Forwarded-Proto`/trusted-proxy misconfiguration presenting as redirect loops; fix the proxy awareness, don't strip HSTS. Be careful adding `preload` (it's hard to undo), but don't remove existing HSTS without flagging that browsers will keep enforcing it anyway until max-age lapses.
- `nosniff` "breaking" a response means the `Content-Type` is wrong; fix the type, keep the header.
- Treat any diff that removes or weakens a header in shared config (nginx, gateway, middleware) as a security change: name it explicitly in your summary with the scope of pages affected.

**Red flags that you're about to violate this:**
- "The partner embed fails with X-Frame-Options, removing it unblocks the integration..."
- "Helmet is causing weird issues, I'll drop it and add headers back as needed..."
- "HSTS is creating a redirect loop, deleting it fixes prod right now..."
- "These headers are hardening polish, the service works without them..."
- "Nobody would bother clickjacking this app..."
- "I'll allow framing everywhere since we might embed it in more places later..."

### Never chmod 777 to Fix a Permission Error

NEVER resolve a permission error with mode 777/666, recursive ownership grabs, or running as root. Find out which user needs access and grant that user the minimum.

World-writable means every process and account on the system can modify the file. That's not a fix; it's an invitation with the error message removed.

- Do not run `chmod 777`/`chmod -R 777`, `chmod 666` on anything executable or sensitive, `umask 000`, or write `mode=0o777` into code that creates files/directories.
- Diagnose first: `ls -l` the path, then find which user the failing process runs as (`ps aux`, the service unit), then `chown appuser:appgroup` the specific directory or add group access (`chgrp` plus `g+rw`). Web servers have a designated user (`www-data`, `nginx`); grant that user, not the world.
- Sane defaults: 755 directories / 644 files for code and static assets; 700/600 for anything containing secrets. Private keys and `.env` files: 600, always. SSH will reject worse, and so should you.
- Never `sudo chown -R` system paths (`/usr`, `/etc`, package-manager territory) to fix a tooling error; fix the tool's prefix or use a user-writable location instead.
- Containers: don't solve volume-permission mismatches with 777 on the host mount or by switching the image to run as root; align the UID/GID (`user:` in compose, `runAsUser`, or chown in the entrypoint for the specific path).
- If a permission error has you genuinely stuck, present the diagnosis (who owns it, who needs it) and the minimal-grant options to the user instead of escalating to "everyone."

**Red flags that you're about to violate this:**
- "777 just while we get it working, then we'll set proper permissions..."
- "It's a single-user VM, there are no other users to worry about..."
- "The recursive flag saves doing this directory by directory..."
- "Running the container as root sidesteps the whole volume mess..."
- "I don't know which user nginx runs as, but 777 covers all cases..."
- "It's only the uploads folder, nothing sensitive lives there..."

### Never Comment Out Auth to Debug

NEVER disable, bypass, weaken, or stub out authentication or authorization to diagnose a problem. Debug with valid credentials, not with the checks removed.

Auth removal is a global change that no test will catch, and "I'll re-enable it after" is how it ships disabled.

- Do not comment out auth middleware, remove `@login_required`/`[Authorize]` decorators, add early returns to auth functions, or replace token validation with `if (true)`.
- Do not hardcode a user ID, role, or "dev user" to skip login. Do not make `getCurrentUser()` return a fixture in non-test code.
- To debug a 401/403: log why the check failed (expired? missing header? bad signature? wrong audience?), inspect the actual token at jwt.io-style decoding locally, and obtain a valid test credential. The rejection reason is the diagnosis.
- If the codebase needs an auth-less mode for local development, it must be an explicit, environment-gated mechanism (`AUTH_DISABLED=true` refused outside `NODE_ENV=development`), designed deliberately, never improvised mid-debugging.
- If you must temporarily weaken a check in a live debugging session at the user's request, re-enable it in the same session and confirm with a test that hits the endpoint unauthenticated and gets a 401. Say explicitly in your summary whether auth was touched.
- Before finishing any task, if you modified any file containing auth logic, re-read your diff specifically for weakened checks.

**Red flags that you're about to violate this:**
- "Let me bypass auth just to confirm the handler works..."
- "I'll hardcode user 1 for now so we can test the flow..."
- "The token setup is complicated, it's faster to skip the check..."
- "I'll add a TODO to restore this decorator..."
- "It's only the staging environment, auth there doesn't protect anything real..."
- "The middleware is probably the bug, so removing it is a valid test..."

### Never Commit .env Files or Untracked Secrets

NEVER stage or commit files that contain credentials. Stage files by explicit path; do not use `git add .`, `git add -A`, or `git commit -a` without reviewing exactly what they will pick up.

A committed secret is in history permanently. Removing the file in a later commit does not remove the secret.

- Before any commit, run `git status` and check the untracked list for: `.env` and variants (`.env.local`, `.env.production`), `*.pem`, `*.key`, `id_rsa*`, `*.p12`, `service-account*.json`, `credentials*`, `*.sqlite`/`*.db`/`*.sql` dumps, and editor-created backup copies of any of these.
- If you create a `.env` file during a session, add it to `.gitignore` in the same step, and create a committed `.env.example` with placeholder values instead.
- If a secret-bearing file is already tracked, do not quietly `git rm` it. Tell the user: the credential needs rotation and possibly history rewriting (`git filter-repo`), because every clone already has it.
- Never bypass a gitignore with `git add -f` to "make the build work." Fix the build to read configuration properly instead.
- Pre-commit hooks or secret scanners failing is a stop signal, not an obstacle. Do not amend, skip hooks (`--no-verify`), or rename files to get past them.

**Red flags that you're about to violate this:**
- "git add . is faster and I changed a lot of files..."
- "The .env only has local dev values in it..."
- "I'll commit it now and gitignore it in a follow-up..."
- "The pre-commit hook is blocking the commit, I'll use --no-verify just this once..."
- "It's a private repo, committed secrets aren't a real exposure..."
- "The user told me to commit everything..."

### Never Disable CSRF Protection to Fix a 403

NEVER fix a CSRF failure by exempting the endpoint or disabling the middleware. The error means the token isn't being sent; fix the sender.

CSRF protection is what stops arbitrary websites from making state-changing requests with your users' session cookies. An exempt endpoint is writable by any page on the internet a logged-in user visits.

- Do not add `@csrf_exempt`, `skip_before_action :verify_authenticity_token`, `csrf().disable()` (Spring), `WTF_CSRF_ENABLED = False`, or remove `csurf`/framework CSRF middleware to make a request succeed.
- Diagnose the sender instead: forms need the token field (`{% csrf_token %}`, `@csrf` in Blade); fetch/axios calls need the token header (read it from the cookie or a meta tag and send `X-CSRF-Token`); axios can be configured once with `xsrfCookieName`/`xsrfHeaderName`. The framework docs have an exact recipe for SPAs — use it.
- In tests, use the framework's test client mechanisms (which handle tokens) rather than disabling CSRF app-wide in the test settings and then copying those settings to prod.
- Legitimate exemptions exist only for endpoints not authenticated by cookies: webhook receivers verified by signature, token-authenticated APIs (`Authorization: Bearer ...`). When exempting such an endpoint, the alternative authentication must already be implemented, and add a comment stating why the exemption is safe.
- Cookie-session APIs need CSRF protection even if they're "APIs": if the browser attaches the auth automatically, the attack works. `SameSite=Lax` cookies reduce exposure but have carve-outs; treat SameSite as a second layer, not the replacement.
- Never set the CSRF cookie to be readable cross-site or echo the token into CORS-exposed responses to "simplify" the SPA integration.

**Red flags that you're about to violate this:**
- "csrf_exempt unblocks the frontend team right now..."
- "This is a JSON API, CSRF is a forms-era problem..."
- "SameSite cookies made CSRF tokens redundant..."
- "I'll disable it globally in dev settings to stop the noise..."
- "The mobile app can't do tokens, so the endpoint has to be exempt..."
- "We'll re-enable verification once the SPA integration stabilizes..."

### Never Disable TLS Certificate Verification

NEVER disable TLS certificate verification to fix a connection error. Not in code, not in environment variables, not in CLI flags, not "just for dev."

Certificate verification failing means it is doing its job. Disabling it converts an inconvenient error into a silent man-in-the-middle vulnerability.

- Do not write `verify=False` (Python requests), `rejectUnauthorized: false` (Node), `InsecureSkipVerify: true` (Go), `NODE_TLS_REJECT_UNAUTHORIZED=0`, `GIT_SSL_NO_VERIFY=1`, `curl -k`/`--insecure`, or `wget --no-check-certificate`.
- Diagnose instead: run `openssl s_client -connect host:443 -showcerts` and identify whether the issue is an incomplete chain, an expired cert, a hostname mismatch, or a private/corporate CA.
- For corporate proxies or internal CAs: add the CA certificate to the trust store (`REQUESTS_CA_BUNDLE`, `NODE_EXTRA_CA_CERTS`, `SSL_CERT_FILE`, or the OS keychain). This is the correct fix in nearly all enterprise environments.
- For self-signed certs on services you control: pin that specific certificate (`verify="/path/to/cert.pem"`, `ca` option in Node) rather than trusting everything.
- For genuinely expired or misconfigured server certs: report it to the user. Fixing the server is the fix.
- If the user explicitly insists on bypassing verification, state the MITM risk in one sentence, scope it to the single call, and add a `SECURITY:` comment marking it for removal.

**Red flags that you're about to violate this:**
- "It's just a local/dev environment, so verification doesn't matter here..."
- "The quickest way to unblock this is to skip the cert check..."
- "It's an internal service, nobody is intercepting internal traffic..."
- "I'll disable it temporarily and we can re-enable it later..."
- "The certificate is self-signed anyway, so verification is pointless..."
- "This is a known workaround for this library..."

### Never Eval User Input

NEVER pass user-controlled strings to an interpreter. No `eval`, no `exec`, no `new Function`, no string-built code. Use the dedicated parser for whatever the input actually is.

Eval on user input is not a vulnerability that leads to code execution; it IS code execution, gift-wrapped.

- Banned with dynamic input: `eval()`/`exec()` (Python, JS, PHP, Ruby), `new Function(string)`, `setTimeout`/`setInterval` with string arguments, `vm.runInContext` as a "sandbox" (Node's vm module is explicitly not a security boundary), Ruby's `instance_eval`/`send` with user-derived names, PHP's `assert()` with strings.
- Parsing data: use `JSON.parse`/`json.loads`. Python-literal strings (single quotes, tuples): `ast.literal_eval`, which evaluates literals only. Never "fix" a JSON parse error by downgrading to eval.
- Math/formula features: use an expression-evaluator library with an explicit function allowlist (mathjs's limited evaluator, simpleeval, govaluate), or write a small parser. A calculator is a parser problem, not an interpreter problem.
- Dynamic dispatch ("call the method named in the request"): use an explicit dict/map of allowed names to functions. Not `getattr(obj, user_string)` unprefixed, not `globals()[name]`, not `obj[userKey]()` on a non-allowlisted object.
- Sanitizing input before eval does not make it safe: keyword blocklists and emptied `__builtins__` are bypassed via attribute traversal and encodings. If the design requires evaluating user code, that's a sandboxing project (separate process, seccomp/jail, time/memory limits) to raise to the user, not an inline decision.
- User-supplied regexes, format strings, and template strings are mini-interpreters of their own; treat "execute this user-provided pattern" with the same suspicion.

**Red flags that you're about to violate this:**
- "eval is the simplest way to support any expression the user types..."
- "I'll strip the word 'import' from the input first, then eval it..."
- "It's not JSON, it's Python-dict syntax, so json.loads won't work, but eval will..."
- "new Function gives the rule engine maximum flexibility..."
- "The vm module sandboxes it, so the eval is contained..."
- "Only our team writes these formulas, and they're not attackers..."

### Never Suppress Security Scanner Findings to Pass CI

NEVER silence a security finding to make a build pass. Fix the finding, or escalate it with your analysis. Suppression is reserved for findings you can specifically argue are false positives, with the argument written down.

A suppression comment is an attestation that a human verified the code is safe. Writing one without that verification is forging the attestation.

- Do not add `# nosec`, `// eslint-disable` (security rules), `// nolint:gosec`, `@SuppressWarnings`, `# noqa`, or scanner inline-ignores as a CI-passing move. Do not add rules to the ignore config, lower severity thresholds, or exclude paths from scanning to the same end.
- For each finding, restate what the scanner believes the problem is, then check whether it's right. It usually is: `shell=True` with a variable, string-built SQL, weak password hash, `verify=False`. The implied fix is usually small; implement it.
- A genuine false positive gets the narrowest suppression (one line, one rule) with the specific reason ("input is a compile-time constant enum"), never a bare suppression or a generic "false positive."
- If you can't tell, escalate: present the finding, your analysis, and the candidate fix to the user. "Not sure, so I silenced it" is the prohibited move.
- Never disable hooks or scanners wholesale (`--no-verify`, removing the CI step, `continue-on-error: true` on the security job) because findings are "noisy." Noise complaints go to the user, not into the pipeline as a dead scanner.
- Existing suppressions aren't precedent; if one looks wrong (a `nosec` on live injection), flag it.

**Red flags that you're about to violate this:**
- "The build needs to be green and this finding is probably a false positive..."
- "nosec is how people handle Bandit noise, the codebase has plenty already..."
- "This rule is too strict in general, I'll turn it off in the config..."
- "The scanner doesn't understand this context, no need to bother the user..."
- "I'll suppress it now and we can investigate properly later..."
- "It's flagged in test code, security findings in tests don't count..."

### Never Weaken CSP to Make an Error Go Away

NEVER fix a CSP violation by adding `'unsafe-inline'`, `'unsafe-eval'`, a wildcard, or a broad scheme source. Fix the code to comply with the policy, or add the single specific origin that's legitimately needed.

A CSP violation means the policy is working. `unsafe-inline` in `script-src` switches the XSS protection off while leaving the header up for show.

- Blocked inline script or `onclick=` handler: move the code into an external file, or use the nonce the framework already emits (`<script nonce="{{ csp_nonce }}">`), or add the script's hash (`'sha256-...'`) to the policy.
- Library demands `'unsafe-eval'`: look for the build that doesn't (e.g., precompiled templates, the CSP-compatible bundle). Only if none exists, surface the tradeoff to the user instead of silently adding it.
- Blocked external resource: add that exact origin (`https://cdn.example.com`), never `https:`, `*`, or a parent wildcard like `*.cloudfront.net` that thousands of strangers can host content on.
- Blocked inline styles: prefer classes/external CSS; `'unsafe-inline'` in `style-src` is lower stakes than in `script-src` but still a last resort, not a reflex.
- Never delete the CSP header, switch it permanently to `Content-Security-Policy-Report-Only`, or comment it out "while we develop." Report-only is a rollout tool, not a fix.
- Treat any diff that touches the CSP as security-relevant: state in your summary exactly which directive changed and why the narrowest version was chosen.

**Red flags that you're about to violate this:**
- "Adding unsafe-inline unblocks this in one line..."
- "The analytics snippet needs inline scripts, every site allows this..."
- "I'll wildcard the CDN domain so we never hit this again..."
- "We can tighten the policy back up before release..."
- "unsafe-eval is required by the framework, so there's no choice..."
- "Report-only mode keeps the policy while making the errors stop..."

### Never Enforce Authorization Only in the Frontend

NEVER treat a client-side check as access control. Every authorization rule must be enforced on the server at the endpoint that performs the action; the frontend version is UX, not security.

Anything running on the user's device is under the user's control: hidden buttons, route guards, disabled states, and localStorage roles are all editable with devtools or replaced entirely by curl.

- When asked to restrict a capability "to admins" (or any role/plan/permission), implement the server-side check on the API endpoint first, then mirror it in the UI. If you only have time for one, it's the server one.
- The server check belongs on the action endpoint itself (middleware or in-handler), not just on the page route that links to it. APIs are called directly.
- Never determine privileges from client-supplied data: a role field in the request body, a flag in localStorage, or an unverified JWT claim. Read the role from the verified session/token server-side.
- Hiding is not removing: a feature-flagged admin panel whose endpoints respond to everyone is an open admin panel. Audit the endpoints, not the navigation.
- Don't trust the client for derived values either: prices, quotas, discounts, and permissions arrive from the client as suggestions; recompute them server-side.
- When completing any "restrict access" task, verify by describing (or writing) the failing case: a direct API request from a non-privileged session must get 403. If you can't show that, the task isn't done.

**Red flags that you're about to violate this:**
- "The button doesn't render for non-admins, so they can't trigger it..."
- "The route guard redirects them before they ever reach the page..."
- "Users won't know this endpoint exists, it's not in the UI..."
- "It's a compiled mobile app, the API isn't visible to users..."
- "The role is right there in the JWT payload, I'll read it client-side..."
- "Server-side checks can come in a follow-up, the demo needs the UI today..."

### Never Ship Default or Seeded Credentials

NEVER create credentials that work without someone explicitly choosing them. Missing secret configuration must crash the app at startup, not activate a fallback.

A default password is a published password. AI-generated defaults are extra-guessable because every model produces the same ones.

- Never write fallbacks for secrets: `process.env.JWT_SECRET || "secret"`, `os.environ.get("ADMIN_PASS", "admin123")`, or config defaults for keys, signing secrets, or passwords. Validate at startup and exit with a clear message when they're missing.
- Seed scripts must not create privileged accounts with fixed passwords. For local dev convenience, generate a random password at seed time and print it once, or read it from a required env var; gate any dev-user creation on an explicit environment check that refuses to run in production.
- `.env.example` and documentation must contain non-working placeholders (`JWT_SECRET=<generate with: openssl rand -hex 32>`), never plausible values someone can deploy unchanged. Include the generation command so the right action is the easy one.
- First-run setup for products: require the operator to set the initial admin credential during installation (setup wizard, CLI prompt, or required env var). Never pre-create `admin/admin` "to be changed on first login" — first login is exactly when the attacker arrives.
- Docker compose files and Helm values count: `POSTGRES_PASSWORD: postgres` in a committed compose file becomes a production password with depressing regularity. Use env-file indirection or generated secrets there too.
- When you encounter an existing default credential pattern while working, flag it; if a known-default value might already be live, the user needs to rotate, not just patch the code.

**Red flags that you're about to violate this:**
- "A fallback secret keeps local development friction-free..."
- "The seed admin is just for the demo environment..."
- "Everyone knows to change the values in .env.example..."
- "It crashes on startup without a default, and crashing is bad UX..."
- "First-login password change will force them to fix it..."
- "The compose file is only for local development anyway..."

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

### Never Hardcode API Keys or Secrets in Source

NEVER write a real credential into a source file. Not temporarily, not commented out, not as a default value, not in a test. Credentials come from the environment or a secrets manager, full stop.

A secret in source enters git history, and git history is forever. Deleting the line later does not unleak it.

- If the user pastes a key into the chat, do not echo it into code. Read it via `os.environ["API_KEY"]` / `process.env.API_KEY` and tell the user to set it (or add it to a gitignored `.env`).
- Fail loudly when the variable is missing: raise at startup with a clear message. Do not fall back to a hardcoded default like `os.environ.get("KEY", "sk-...")` — the fallback is the leak.
- In tests, use obviously fake values (`"test-key-not-real"`) or fixtures injected by the test runner. Never copy a working key into a test to make it pass.
- In examples, docs, and scaffolded configs, use placeholders that cannot work: `<YOUR_API_KEY>`, not a realistic-looking value.
- Database URLs, signing secrets, SMTP passwords, and webhook secrets are all credentials, not just things named "api_key."
- If you find an existing hardcoded secret while working, flag it: it needs rotation, not just removal, because history already has it.

**Red flags that you're about to violate this:**
- "I'll put the key inline for now so we can verify the integration works..."
- "It's a private repo, nobody outside the team can see it..."
- "I'll add a TODO to move it to env vars before release..."
- "This is just a local script, it won't be committed..."
- "A default value makes the code work out of the box..."
- "It's only the staging key, not production..."

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

### Never Pass Request Bodies Straight to Models

NEVER write client-supplied objects directly into a database record. ALWAYS pick the allowed fields explicitly per endpoint.

If the handler writes whatever keys arrive, clients control every column, including `role`, `is_admin`, `verified`, `owner_id`, and `price`.

- Do not write `Model.update(req.body)`, `user.update(**request.json)`, `Object.assign(entity, req.body)`, `{...req.body}` into a create/update call, or `findByIdAndUpdate(id, req.body)`.
- Allowlist explicitly: `const { name, email, avatarUrl } = req.body; user.set({ name, email, avatarUrl })`, or a serializer/DTO/schema with the permitted fields enumerated (Rails strong parameters' `permit`, Django form/serializer `fields`, a Pydantic/zod schema containing only client-settable fields, `.pick()` on a broader schema).
- Never reuse the model's full schema as the request schema. A zod/Pydantic validator that includes `role` validates the attack instead of blocking it; define a separate input schema per endpoint.
- Privileged fields (`role`, flags, balances, foreign keys like `org_id`/`owner_id`) change only through dedicated endpoints with their own authorization, never as a side effect of a general update.
- Mind nested writes: ORMs that accept relation payloads (`{profile: {...}}`, `accepts_nested_attributes_for`) extend mass assignment one table deeper. Allowlist nested fields too.
- Apply the same rule to responses: do not `res.json(user)` raw model instances; serialize through an explicit field list so password hashes, tokens, and internal flags never leave the server.

**Red flags that you're about to violate this:**
- "Spreading the body keeps the handler generic for future fields..."
- "The frontend only sends name and email, so that's all that arrives..."
- "Our validation middleware already checks the body against the schema..."
- "I'll just exclude the password field, the rest are harmless..."
- "It's a PATCH endpoint, partial updates are supposed to be flexible..."
- "The model defines which fields exist, the database will reject bad ones..."

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

### Never Redirect to User-Supplied URLs

NEVER pass a user-controlled value to a redirect without strict validation. Prefer designs where the client never supplies a URL at all.

An open redirect turns your trusted domain into a phishing launcher: victims verify YOUR domain, log in on YOUR page, and land on the attacker's.

- Best: don't accept URLs. Accept a key into a server-side map of named destinations (`?dest=dashboard`), or store the intended destination in the session before redirecting to login.
- If a path parameter is unavoidable, enforce all of: it starts with exactly one `/` (reject `//` and `/\`, which browsers treat as protocol-relative), it contains no scheme or backslash, and then resolve it against your own origin. In frameworks, use the built-in helper where one exists (Django's `url_has_allowed_host_and_scheme`, Rails' `redirect_to ... allow_other_host: false`) instead of hand-rolling.
- Never validate with substring or prefix string checks: `url.includes("myapp.com")`, `startsWith("https://myapp.com")` (defeated by `https://myapp.com.evil.io`), or regexes you wrote at 4pm. Parse with the URL parser and compare the origin exactly.
- The same rule covers cousins: `window.location = userValue` in frontend code, `Location` headers built from input, OAuth `redirect_uri` handling (exact-match against registered URIs, never prefix-match), and "link out" interstitial endpoints.
- `javascript:` and `data:` schemes must never survive validation; rejecting everything that isn't a same-origin path handles this automatically.
- If product genuinely requires redirecting off-site (partner links), use an explicit allowlist of full origins and show an interstitial; say so in the code with a comment.

**Red flags that you're about to violate this:**
- "It's just a post-login convenience parameter, who would tamper with it..."
- "I check that the URL starts with a slash, so it stays on our site..."
- "The value contains our domain name, that proves it's ours..."
- "Open redirects are low severity anyway, not worth the ceremony..."
- "OAuth needs flexible redirect URIs for all our environments..."
- "The frontend builds this URL, so it's not really user input..."

### Scrub PII Before It Reaches Error Trackers and Analytics

NEVER send personal data to third-party telemetry (error trackers, analytics, session replay, tracing) as debugging or tracking context. Identify users by opaque internal ID; allowlist every attached field.

Telemetry vendors are an unaudited copy of whatever you send them, with their own retention, access, and breach surface. Context that includes PII is a privacy incident on a delay.

- Identify users as `setUser({ id: internalId })`. Do not attach email, name, phone, addresses, or usernames to events; if support needs to find a user's errors, the internal ID is searchable on both sides.
- Never attach whole objects as context: request bodies, form state, Redux/app state, user records, or `extra: req.body`. Attach named, individually chosen fields.
- Configure the SDK's scrubbing: `beforeSend` hooks to delete known-sensitive keys, server-side data scrubbers, and denylists for field names (`password`, `email`, `ssn`, `token`, `card`). Turn ON the SDK's default PII filters and leave `sendDefaultPii`-style options OFF.
- Session replay and heatmap tools: mask all inputs by default (`maskAllInputs: true` or equivalent), and explicitly block replay on pages handling payments, health data, or identity documents.
- Analytics events carry the same rule: `signup_completed` with a plan name is fine; with the user's email and company as event properties, it's PII replication. Marketing can join on the internal ID server-side.
- URLs leak too: if routes embed emails or names (`/users/jane@example.com`), telemetry inherits them; route by ID and the problem disappears upstream.
- Regulated categories (health, payment card data, government IDs) must never reach general-purpose telemetry, full stop; that's a compliance boundary, not a scrubbing preference.

**Red flags that you're about to violate this:**
- "Attaching the user object makes every error instantly debuggable..."
- "The error tracker is a trusted vendor, it's not like posting publicly..."
- "Support wants to search errors by email, so email has to be on the event..."
- "Session replay needs real inputs to be useful for UX research..."
- "It's just the email address, hardly sensitive data..."
- "We can add scrubbing once the privacy team asks for it..."

### Never Bind Dev Servers and Debug Tools to 0.0.0.0

NEVER fix a connectivity problem by binding development services to all interfaces. Default to `127.0.0.1`; widen only as far as the specific need requires, and never with debug modes or unauthenticated services.

`0.0.0.0` means "everyone who can reach this machine," and on cloud VMs and shared networks that's not a metaphor. Internet-wide scanners find newly exposed ports in minutes.

- Dev servers, REPLs, admin UIs, and anything with `debug=True` bind to `127.0.0.1` by default. Flask debug mode on a reachable interface is remote code execution via the Werkzeug console; Node's `--inspect` is a REPL in your process — keep both strictly local.
- Docker compose: `ports: "6379:6379"` publishes on all host interfaces. Write `ports: "127.0.0.1:6379:6379"` for host-only access — and container-to-container traffic usually needs no `ports` at all; containers on the same network reach each other by service name.
- Inside a container, where `0.0.0.0` is required for port mapping, the security boundary moves to the host's publish address and the cloud security group; verify those are restrictive before calling it done, and say so.
- Databases and caches reachable beyond localhost get a password first (`requirepass`, auth enabled), exposure second. Unauthenticated Redis/Mongo/Elasticsearch on a network interface is a published copy of your data.
- Need access from a phone or teammate: prefer a tunnel (SSH `-L`, mesh VPN, the framework's tunnel option) or knowingly bind to the specific LAN interface, on a trusted network, without debug mode.
- Never combine the broad bind with `debug=True`, default credentials, or a disabled firewall to make the test work; that stack of "temporary" choices is the standard breach recipe.

**Red flags that you're about to violate this:**
- "0.0.0.0 is the standard fix for container networking..."
- "It's just my dev machine, nobody is scanning it..."
- "The database has no data worth stealing yet..."
- "I'll bind wide to test from my phone, then change it back..."
- "We're behind the office firewall, the LAN is trusted..."
- "The compose file needs the port published or the app can't reach Redis..."

### Never Put Secrets in Frontend Code or Bundles

NEVER place a secret in code delivered to the client. `NEXT_PUBLIC_`, `VITE_`, `REACT_APP_`, and `EXPO_PUBLIC_` prefixes inline the value into the public bundle; they are publication mechanisms, not configuration.

If the browser can use the key, every visitor has the key. Minification, compilation, and obfuscation do not change this.

- Before exposing any env var to the client, classify it: publishable values (analytics IDs, map keys with referrer restrictions, Stripe *publishable* keys, public API URLs) may use the prefix; secret keys, service-role keys, signing secrets, and database URLs may not, ever.
- When a frontend needs a privileged API, build the thin backend route: the browser calls `/api/your-endpoint`, the server (API route, edge function, serverless function) holds the key in a non-prefixed env var and makes the real call. This is the fix for "the key is undefined in the browser," not the rename.
- The same rule covers mobile and desktop apps: keys in compiled binaries are extracted with `strings` and a proxy. "Compiled" is not "secret."
- Distinguish key types by name: Stripe `pk_` is publishable, `sk_` is secret; Supabase `anon` key is public-by-design (RLS enforces security), `service_role` bypasses RLS and must never reach a client. If unsure which kind a key is, treat it as secret and ask.
- Server-only secrets should fail loudly if imported into client code; where the framework supports it, use its taint/server-only mechanisms (`import "server-only"`) on modules that read secrets.
- If a secret has already shipped in a bundle, rotation is mandatory; deleting it from the next deploy doesn't recall the cached JS.

**Red flags that you're about to violate this:**
- "Renaming it NEXT_PUBLIC_ fixes the undefined error..."
- "The key is needed client-side, so it has to be in the bundle..."
- "It's minified and the variable name is mangled, nobody will find it..."
- "This is a mobile app, the binary isn't readable like a webpage..."
- "Adding a backend route for one API call is over-engineering..."
- "It's a low-value key, even if someone finds it, who cares..."

### Never Log Credentials or Full Request Bodies

NEVER log secrets, and never log whole request/response objects on endpoints that can carry them. Log specific, named, non-sensitive fields instead.

Logs have weaker access control and longer retention than your database. A token in a log is a token leaked.

- Never log: passwords, tokens (bearer, refresh, session, CSRF), API keys, `Authorization`/`Cookie`/`Set-Cookie` headers, security answers, OTP codes, private keys, or full card numbers.
- Do not dump containers that might hold them: `req.body`, `req.headers`, `request.POST`, config objects, env (`process.env`, `os.environ`), caught exception objects from auth libraries, or axios/fetch error objects (which embed the request, headers included).
- Log selectively: `logger.info("login failed", {username, reason})`, not the body. If a sensitive value must be referenced, log a redacted form (`tok_...last4`) or a hash, and say which.
- On auth endpoints specifically, the password field is present in the body by definition. Never add body logging there, even at debug level; debug level runs in prod more often than anyone admits.
- When adding diagnostic logging during a session, list every log line you added in your summary so they can be reviewed and removed.
- If the project has a redaction/allowlist mechanism in its logger, route new logging through it instead of around it.

**Red flags that you're about to violate this:**
- "I'll log the whole request just while we track this down..."
- "It's debug level, it won't show up in production..."
- "Logging the headers will show us if the token is being sent..."
- "Our logs are internal, only engineers can read them..."
- "I'll dump the config object to see what's actually loaded..."
- "One verbose log line is the fastest way to see everything at once..."

### Never Render User Input as a Template

NEVER compile or render a string containing user input as a server-side template. User data goes into the template context as a variable; it never becomes part of the template source.

Template engines evaluate expressions. Rendering user input as a template hands users an expression evaluator, which in Jinja2, ERB, Freemarker, and friends escalates to remote code execution.

- Never do: `render_template_string(f"...{user_value}...")`, `Template(user_string).render()`, `ERB.new(params[...])`, `Handlebars.compile(userTemplate)`, or string-concatenating anything user-derived into template source before compilation.
- Always do: `render_template("greeting.html", name=name)` / `res.render("greeting", {name})`, with the template source fixed in a file and the user value passed as context, where the engine escapes it.
- The pre-interpolation variant is the sneaky one: an f-string or `+` that mixes user data into the template string *before* the render call is already the vulnerability, even though the render call itself looks clean.
- For user-customizable content (email templates, notification formats), do not expose the application's template engine. Use a logic-less or sandboxed option: a strict allowlist of `{placeholder}` tokens you substitute yourself with `str.replace`-style logic, Mustache in logic-less mode, or Jinja2's `SandboxedEnvironment` if expressions are truly required (and treat even that as a risk to flag).
- Format strings count: `user_string.format(**data)` on a user-controlled format string leaks object internals via `{0.__class__...}`. Same rule, smaller blast radius.
- If you see `{{7*7}}` rendering as `49` anywhere user input flows, that is an active RCE vector; flag it immediately.

**Red flags that you're about to violate this:**
- "render_template_string saves creating a file for one line of HTML..."
- "Admins write these templates, and admins are trusted..."
- "I'll interpolate the name first, then render the result..."
- "It's just an email template, there's no dangerous data nearby..."
- "The engine escapes variables, so this is safe by default..."
- "Users only have access to a few placeholder variables anyway..."

### Never Build Shell Commands From User Input

NEVER interpolate user-controlled data into a shell command string. ALWAYS pass arguments as an array to an API that does not invoke a shell.

A command string plus user input is remote code execution waiting for one semicolon, backtick, or `$()`.

- Python: use `subprocess.run([...], shell=False)` with a list of arguments. Do not use `shell=True`, `os.system`, or `os.popen` with any dynamic content.
- Node: use `execFile` or `spawn` with an args array. Do not use `child_process.exec` or backtick-built command strings with dynamic content.
- Go/Rust/Java: `exec.Command(name, args...)` and equivalents already separate arguments; do not wrap commands in `sh -c` to get string convenience back.
- Filenames and hostnames count as user input. So do values from your own database if any user ever wrote them.
- If an argument starts with `-`, an attacker can smuggle flags (`--output=/etc/cron.d/x`). Use `--` to terminate option parsing where the tool supports it, and validate expected formats.
- If you genuinely need shell features (pipelines, globbing), construct the pipeline in code with multiple `spawn` calls, or quote with `shlex.quote` as a last resort and say why in a comment.
- Escaping with string replacement (`.replace("'", "\\'")`) is not a fix. Do not write it.

**Red flags that you're about to violate this:**
- "shell=True is simpler and this input comes from a trusted form..."
- "It's just a filename, filenames are harmless..."
- "I'll strip semicolons from the input first..."
- "This script only runs in CI, nobody malicious touches CI..."
- "The exec string version is what the docs show..."
- "I need the pipe character, so I have to use the shell..."

### Never String-Interpolate User Input Into SQL

NEVER build SQL queries by concatenating or interpolating values into the query string. ALWAYS use parameterized queries or an ORM/query builder. This applies to prototypes, scripts, internal tools, and "temporary" code equally.

String-built SQL is SQL injection. There is no safe amount of it, and escaping by hand does not count as safe.

- Do not write `f"... WHERE id = {x}"`, `"... " + x`, `` `... ${x}` ``, `%` formatting, or `.format()` into any SQL string. This includes values that "come from our own frontend" — the frontend is not a trust boundary.
- Use placeholders: `cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))`, `db.query("... WHERE id = $1", [id])`, prepared statements in Java/Go, bound parameters everywhere else.
- Identifiers (table/column names, ORDER BY fields) cannot be parameterized: validate them against a hardcoded allowlist, never pass them through.
- For dynamic filters, build the clause structure in code and bind every value; never splice user input into the clause text.
- LIKE patterns: bind the parameter and escape `%`/`_` in the value, not in the query string.
- If you find existing interpolated SQL while editing a file, flag it to the user even if it is not the code you were asked to change.

**Red flags that you're about to violate this:**
- "This is just a prototype, parameterization can come later..."
- "The value is an integer from our own code, it can't contain SQL..."
- "I'll sanitize the input with a regex first, so interpolation is fine..."
- "This is an internal admin tool, only employees use it..."
- "The ORM makes this query awkward, raw SQL is cleaner here..."
- "I escaped the quotes manually, so it's safe..."

### Never Return Stack Traces or Internal Errors to Clients

NEVER send internal error details in HTTP responses. Log the full error server-side with a correlation ID; return the ID and a generic message to the client.

Error responses are documentation for attackers: stack traces map your code, database errors map your schema, and distinct error messages become oracles.

- In catch blocks: `logger.error({err, requestId})` server-side, then respond `{ "error": "Internal error", "requestId": "..." }`. Never include `err.message`, `err.stack`, exception class names, SQL text, or file paths in the response body for unexpected errors.
- `err.message` is not safe just because it's short: driver and library messages embed table names, constraint names, hosts, and paths. Treat any message you didn't write as internal.
- Expected, user-fixable errors (validation failures, "name is required") should be specific — that's UX, not leakage. The line: messages you authored about THEIR input are fine; messages the system generated about YOUR internals are not.
- Auth flows must return identical errors and similar timing for "no such user" and "wrong password" ("Invalid email or password"), and registration/password-reset flows need the same care ("If that account exists, we sent an email").
- Set production config to suppress framework debug pages: Express error handler without stacktraces in prod, Django `DEBUG=False`, Rails `consider_all_requests_local = false`. Verify the production branch of the config, not just the default.
- GraphQL: disable verbose error extensions and stack traces in production (`includeStacktraceInErrorResponses: false`, mask internal errors); the default in several servers is chatty.
- 404 versus 403 on resources others own: prefer uniform 404 so existence isn't leaked.

**Red flags that you're about to violate this:**
- "Returning err.message makes debugging integration issues so much easier..."
- "The client team asked for descriptive errors..."
- "It's just the exception text, not a full stack trace..."
- "Telling users whether the email or the password was wrong is better UX..."
- "We'll turn off debug pages when we set up real prod config..."
- "Our API consumers are internal, they can see internals..."

### Never Put Tokens or Keys in URL Query Strings

NEVER carry long-lived credentials in URLs. API keys go in the `Authorization` header; session state goes in cookies or headers; one-time links get short expiry and single-use enforcement.

URLs are copied everywhere by default: access logs, proxy logs, Referer headers, browser history, analytics. A key in a query string is a key distributed to every system that ever sees the request line.

- API authentication: `Authorization: Bearer <token>` (or the provider's header). Do not design `?api_key=` parameters into new endpoints, and do not use a provider's legacy query-param auth when a header form exists. Examples and docs you write follow the same rule.
- Never place session tokens, JWTs, or OAuth access tokens in query strings or in redirect URL parameters. For browser flows, use the authorization-code flow where tokens move in POST bodies and cookies, not the URL bar.
- Links that must carry a secret (password reset, magic login): single-use tokens, expiring in minutes-to-hours, invalidated on use and on password change, with the landing page immediately exchanging the token for a session and scrubbing it from the address bar.
- Mint presigned URLs (S3-style) with the shortest workable expiry, scoped to one object and method; an unexpiring signed URL is a permanent public link in disguise.
- Defense in depth for pages that ever see sensitive URLs: `Referrer-Policy: strict-origin-when-cross-origin` or stricter, and configure logging/telemetry to redact known token parameters.
- GET-with-body-in-query designs ("?password=" on a login form because GET was easier) are the same bug with less dignity; credentials ride in POST bodies.

**Red flags that you're about to violate this:**
- "Query-param auth means users can test the API right in the browser..."
- "The link token is random and unguessable, the URL is as good as private..."
- "Our logs are internal, who cares if the key appears there..."
- "I'll give the presigned URL a one-year expiry so customer links never break..."
- "The provider's docs show api_key as a parameter, I'll match their example..."
- "It's HTTPS, the URL is encrypted anyway..."

### Never Deserialize Untrusted Data With Unsafe Loaders

NEVER use a deserializer capable of instantiating arbitrary objects on data that crosses a trust boundary. Default to JSON or another data-only format.

Unsafe deserialization is remote code execution: the payload runs during parsing, before your validation code ever sees the data.

- Banned on external or attacker-influenceable data: `pickle.loads`, `yaml.load` (use `yaml.safe_load`), `eval`/`ast.literal_eval` confusion (only `literal_eval` is safe, and prefer JSON anyway), PHP `unserialize`, Java `ObjectInputStream` on raw input, Ruby `Marshal.load`, `node-serialize`/`serialize-javascript` round-trips.
- "Attacker-influenceable" is broad: cookies and anything client-supplied, cache entries (Redis/memcached) if any other process writes them, queue messages, uploaded files, cross-service payloads, and database blobs other code paths can write. Your own storage is not a trust boundary if inputs ever flow into it.
- Default serialization format: JSON. For schemas/performance use protobuf, msgpack (without object extensions), or CBOR. These parse data, not constructors.
- Pickle is acceptable only for same-process or fully internal artifacts (e.g., a local model file you built), and even then prefer formats like safetensors where they exist. Never unpickle anything downloaded.
- If a session/cookie must round-trip server data, sign it (HMAC, or the framework's signed-cookie mechanism) and verify before parsing, and still keep the payload JSON.
- When you encounter existing `yaml.load` or `pickle.loads` in code you're editing, switch to the safe variant or flag it; do not propagate the pattern to new call sites.

**Red flags that you're about to violate this:**
- "Pickle handles arbitrary Python objects, JSON would need a schema..."
- "We wrote this cache entry ourselves, so it's trusted data..."
- "yaml.load is what the older docs show, and it works..."
- "The cookie is ours, the client just stores it for us..."
- "It's an internal queue, only our services publish to it..."
- "I'll validate the object right after deserializing it..."

### Never Inject User Data Into HTML Unescaped

NEVER render user-controlled content through an HTML-injection sink without sanitization. Default to text rendering; treat every escape hatch as requiring justification.

Frameworks escape output by default. `innerHTML`, `dangerouslySetInnerHTML`, `v-html`, `| safe`, `{!! !!}`, and `<%- %>` are opt-outs, and opting out with user data is stored XSS.

- Rendering text: use `textContent`, JSX `{value}`, `{{ value }}` (auto-escaping templates). Never switch to an HTML sink just to get line breaks; use CSS `white-space: pre-wrap` or split into elements.
- Rendering rich text/markdown from users: sanitize the produced HTML with DOMPurify (or bleach in Python, sanitize-html in Node) immediately before the sink. Markdown renderers do not sanitize by default; `marked(userText)` into `innerHTML` is XSS.
- Building HTML server-side by string concatenation with user values is the same bug; use the template engine's escaping, never manual `replace('<', '&lt;')` half-measures.
- URLs are a sink too: validate that user-supplied `href`/`src` values have `http:`/`https:` schemes; `javascript:alert(1)` survives HTML escaping.
- Do not write your own sanitizer or regex-strip `<script>` tags; bypasses are a hobby industry. Use the maintained library.
- "From our database" is not "safe": if a user ever wrote it, it's user content, including names, filenames, and webhook payloads from third parties.
- When you must use a dangerous sink legitimately (sanitized markdown, trusted CMS content), add a comment stating the data source and why it's safe.

**Red flags that you're about to violate this:**
- "textContent strips the formatting, innerHTML preserves it..."
- "This field is just a display name, nobody puts HTML in a name..."
- "The value comes from our own API, it's already clean..."
- "I'll strip script tags with a regex before inserting..."
- "It's an admin-only page, admins won't attack themselves..."
- "The markdown library probably escapes things..."

### Never Fetch User-Supplied URLs Server-Side Unchecked

NEVER have the server fetch a user-provided URL without SSRF controls. Your backend has network access the user doesn't; an unchecked fetch lends it to them.

- Block by resolved IP, not hostname strings. Resolve the hostname, reject private/reserved/link-local ranges (10/8, 172.16/12, 192.168/16, 127/8, 169.254/16 — the cloud metadata service lives at 169.254.169.254 — plus IPv6 loopback/ULA/link-local), then connect to the IP you validated, not via a second DNS lookup (that gap is DNS rebinding). Use a maintained SSRF-safe fetch library where one exists (e.g., ssrf-req-filter/safe variants in Node, Advocate-style wrappers in Python) rather than hand-rolling.
- Disable automatic redirect following, or re-run full validation on every hop. A compliant external URL that 302s to the metadata endpoint is the standard bypass.
- Allow only `http`/`https` schemes. `file://`, `gopher://`, `ftp://`, and `dict://` turn fetchers into local file readers and raw-socket tools.
- Prefer an allowlist when the feature permits it: importers that only support specific providers should match exact hosts, not "any URL."
- Constrain the blast radius regardless: short timeouts, response size caps, no internal auth headers attached to outbound user-driven requests, and where infrastructure allows, route these fetches through an egress proxy or isolated network segment with no internal routes.
- These rules apply to every server-side fetch of user-influenced URLs: webhook delivery and "test webhook" buttons, link unfurlers, PDF/screenshot generators (the headless browser fetches subresources too), file importers, RSS readers, and OpenID/OAuth discovery URLs.
- String checks like `if "localhost" in url` or `url.startswith("http://10.")` are not controls. Don't write them as the defense.

**Red flags that you're about to violate this:**
- "It's just a link preview, we only read the title tag..."
- "I block 'localhost' and '127.0.0.1', the internal stuff is covered..."
- "Our VPC is private, external users can't reach anything sensitive through us..."
- "The webhook URL was validated when the user saved it..."
- "Redirects are handled by the HTTP library, that's below our layer..."
- "The headless browser only renders, it doesn't really 'fetch'..."

### Never Build File Paths From User Input

NEVER pass user-controlled strings into a filesystem path without containment verification. Resolve the full path, then verify it is still inside the allowed base directory before any read, write, or delete.

`path.join(base, userInput)` is not containment: `..` segments and absolute paths escape it silently.

- After joining, canonicalize and check: Python `resolved = (base / name).resolve(); resolved.relative_to(base.resolve())` (raises on escape), Node `const p = path.resolve(base, name); if (!p.startsWith(path.resolve(base) + path.sep)) throw`, Java `getCanonicalPath().startsWith(...)`, Go avoid manual joins and use `os.OpenRoot` / `filepath.IsLocal`.
- Beware Python's `os.path.join`: an absolute second argument replaces the base entirely. The containment check catches this; input filtering does not.
- Do not sanitize with blocklists (`replace("../", "")`, reject `..`). Encoded forms, `....//`, and Windows backslashes get through. Structural verification, not string cleaning.
- Best option where feasible: don't accept paths at all. Accept an ID, look the real path up server-side, and store uploads under server-generated names (`uuid4()` plus a validated extension), keeping the user's original filename as display metadata only.
- For uploads, also ignore any directory components in the client-supplied filename (`os.path.basename` first, then still verify containment).
- Symlinks inside the base directory can re-escape it; canonicalize (resolve symlinks) before the containment check, as the examples above do.
- Archive extraction (zip/tar) has the same bug as entries named `../../x` (Zip Slip): verify each entry's resolved destination before extracting.

**Red flags that you're about to violate this:**
- "path.join keeps everything under the uploads directory..."
- "I strip out '../' from the parameter, so traversal isn't possible..."
- "The filenames come from our own upload form, not attackers..."
- "This endpoint is only used by the admin panel..."
- "It's a quick static file route, the framework probably handles it..."
- "Checking for '..' in the string covers the traversal case..."

### Never Fix CORS Errors With Wildcard Origins

NEVER respond to a CORS error by allowing all origins. CORS is an access-control policy, not a connectivity bug; the fix is naming the origins that should have access.

- Do not set `Access-Control-Allow-Origin: *` on any endpoint that serves user-specific data or sits behind authentication.
- Do not reflect the request's `Origin` header back unconditionally, and never combine reflection with `Access-Control-Allow-Credentials: true`. That grants every website on the internet credentialed access to the API.
- Configure an explicit allowlist instead: `cors({ origin: ["https://app.example.com", "https://staging.example.com"] })` or the framework equivalent. Add the dev origin (`http://localhost:3000`) explicitly for local work.
- Validate allowlist entries by exact match. Do not match with `startsWith` or a substring regex; `https://app.example.com.evil.io` passes both.
- `*` is acceptable only for truly public, unauthenticated, non-user-specific resources (public CDN assets, an open dataset), and say so in a comment when you use it.
- If the CORS error is happening because frontend and backend ports differ in dev, prefer a dev-server proxy over loosening the API's policy.

**Red flags that you're about to violate this:**
- "The wildcard unblocks development and we can tighten it before launch..."
- "Reflecting the origin is the standard workaround when you need credentials..."
- "It's an internal API, CORS doesn't really matter here..."
- "The mobile app doesn't send an Origin header anyway, so this is harmless..."
- "Every Stack Overflow answer for this error says to allow all origins..."
- "I'll match any subdomain of example.com with a regex to keep it flexible..."

### Never Grant Wildcard Cloud Permissions to Fix Access Errors

NEVER fix a cloud permission error with `Action: "*"`, `Resource: "*"`, admin/owner roles, or `cluster-admin`. Grant the specific action on the specific resource the error names.

A service's permissions are the blast radius of its compromise. Wildcards convert any bug in the service into account-wide access.

- Read the denial message: it names the exact action (`s3:GetObject`) and usually the ARN. Write the policy from it: that action, scoped to the bucket/table/queue ARN, not `*`.
- Permission errors arrive iteratively; that's normal. Add actions as they surface, or enumerate the service calls in the code and grant those. Do not end the loop with a wildcard out of fatigue.
- Never attach `AdministratorAccess`/`roles/owner`/subscription-level Owner to a workload identity, and never hand `cluster-admin` to an app's Kubernetes service account. If the user explicitly requests it, state the blast radius in one sentence and ask once.
- `iam:PassRole` with `Resource: "*"` is privilege escalation (pass an admin role to a resource you control); scope PassRole to the specific role ARN, with conditions where supported.
- Don't fix object-access errors by making buckets public or by opening security groups to `0.0.0.0/0`; identify the principal that needs access and grant it to that principal. Public access and all-IPs ingress need an explicit product reason stated in a comment or commit message.
- Apply the same scoping to local stand-ins: database users created for an app get table-level grants, not superuser; tokens get the narrowest available scopes.
- When you genuinely cannot determine the needed set up front, grant a tightly scoped guess, and leave the iteration visible to the user rather than silently widening.

**Red flags that you're about to violate this:**
- "Action star unblocks the deploy and we'll scope it down post-launch..."
- "I keep hitting new AccessDenied errors, broad permissions end the whack-a-mole..."
- "It's a dev account, over-permissioning there is harmless..."
- "AdministratorAccess is what the tutorial attaches..."
- "The service is internal, nothing malicious will ever run as it..."
- "Scoping ARNs is brittle, names might change later..."

### Rate-Limit Login, OTP, and Reset Endpoints

ALWAYS apply rate limiting and attempt caps when building authentication-adjacent endpoints, and NEVER remove or hollow out an existing limit to fix tests or load complaints.

An unthrottled login is a password oracle; an unthrottled 6-digit OTP check is a solvable puzzle, not a control.

- Endpoints that need limits by default: login, OTP/2FA verification, password reset request and reset-token submission, email verification, signup (abuse), API key validation, and anything comparing a short code. Build the limit with the endpoint, not as a hardening backlog item.
- Limit on two axes: per-target-account (stops distributed guessing against one user) and per-IP (stops one source spraying many accounts). IP-only misses botnets; account-only enables lockout-as-harassment — use both, with the account axis escalating to delays or step-up (CAPTCHA) rather than hard permanent lockout.
- Tiny keyspaces get hard caps: OTP and SMS codes allow 5-10 attempts, then invalidate the code and issue a new one. Reset tokens: long, random, single-use, expiring — and still capped.
- Use real infrastructure: the framework's limiter or a Redis-backed counter. An in-memory `Map` in one process limits nothing behind a load balancer; note this when you see it.
- When a limit blocks tests or load runs, the fix is test-shaped: dedicated test hooks, limiter exemptions for specific test credentials in non-prod config, or resetting counters between runs. Never raise the global threshold to "basically off," delete the middleware, or add an `X-Skip-RateLimit` style header check that ships to production.
- Respond to limited requests with 429 and no oracle: the response must not reveal whether the password would have been correct, or whether the account exists.

**Red flags that you're about to violate this:**
- "Rate limiting is an optimization, the auth logic is what matters for now..."
- "The E2E suite keeps tripping the limiter, I'll bump the max way up..."
- "Per-IP limiting covers it, attackers come from one place..."
- "Six digits plus a 10-minute expiry is too short a window to brute force..."
- "I'll add a bypass header so QA stops complaining..."
- "The in-memory limiter works in dev, distributed counters are over-engineering..."

### Remove Debug Endpoints and Debug Mode Before Merge

NEVER leave debugging affordances in completed work. Any route, flag, or mode you add to help yourself debug must be removed, or explicitly environment-gated, before the task is done, and disclosed either way.

Debug endpoints are unauthenticated by design and invisible in review by accident. They ship.

- Do not create routes like `/debug/*`, `/test-login`, `/dev/reset`, or magic query parameters (`?skip_auth=1`, `?as_user=`) as throwaway aids. If you create one anyway, removing it is part of the task, not a follow-up.
- Never commit `debug=True` (Flask), `DEBUG = True` (Django), or equivalents in code or shared config. Flask debug mode is an in-browser code execution console, not a log level. Debug flags belong in environment variables, with the committed default being off.
- Auth-bypass test users, hardcoded "dev tokens," and `if (user === 'test') return true` shortcuts count as debug affordances. Same rule.
- If a diagnostic endpoint should exist permanently (health checks, build info), it gets the production treatment: behind auth where appropriate, minimal output (no config dumps, no env, no object internals), and a deliberate decision about exposure.
- Before declaring any task complete, re-scan your own diff for routes, flags, conditionals, and config you added for debugging, and state in your summary either "removed" or "kept, gated by X, because Y."
- If you find someone else's leftover debug endpoint while working, flag it; do not assume it's intentional.

**Red flags that you're about to violate this:**
- "This route makes testing so much easier, I'll leave it for the team..."
- "debug=True is fine here, this is the dev settings file... I think..."
- "I'll mark the backdoor with a TODO so someone removes it later..."
- "Nobody will discover the endpoint, it's not linked anywhere..."
- "The test user only works in staging anyway... probably..."
- "Tearing this down now would just slow the next debugging session..."

### Set Secure Flags on Session Cookies

ALWAYS set `HttpOnly`, `Secure`, and `SameSite` on cookies that carry authentication. The bare `res.cookie(name, value)` form is not acceptable for session material.

Each missing flag is a live attack class: no HttpOnly means any XSS steals the session; no Secure means networks see it; no SameSite means cross-site requests use it.

- Default for session/auth cookies: `{ httpOnly: true, secure: true, sameSite: "lax", path: "/" }` (Express), `SESSION_COOKIE_HTTPONLY/SECURE/SAMESITE` (Django), `cookie SameSite=Lax; Secure; HttpOnly` however your stack spells it. Use `strict` where the UX tolerates it; use `none` only with `secure: true` and a documented cross-site requirement.
- For local HTTP development, gate `secure` on environment (`secure: process.env.NODE_ENV === "production"`), never delete it. Better: run dev on https or localhost, which browsers treat as secure context.
- Set sensible lifetimes: hours-to-days for auth, not a year to "avoid annoying re-logins." Long-lived "remember me" belongs in a separate rotating token with server-side revocation.
- Rotate the session identifier on login and privilege change (`req.session.regenerate`; framework login helpers do this — don't bypass them), and invalidate server-side on logout, not just by clearing the browser cookie.
- Add the `__Host-` prefix to the cookie name where supported; it makes the browser enforce Secure, no Domain attribute, and `path=/`.
- Do not move tokens to `localStorage`/`sessionStorage` to sidestep cookie configuration: storage is readable by any script on the page, which converts every XSS into full token theft. HttpOnly cookies plus CSRF protection remains the default pattern for browser sessions.
- Cookies that aren't auth (preferences, analytics) may relax HttpOnly when client JS genuinely needs to read them; say which cookie and why in a comment.

**Red flags that you're about to violate this:**
- "The bare cookie call works fine, flags are polish for later..."
- "secure: true breaks localhost, so I'll leave it off everywhere..."
- "localStorage is simpler than dealing with cookie attributes..."
- "A one-year expiry saves users from re-logging in..."
- "SameSite defaults are good enough in modern browsers..."
- "It's an internal app on the office network, transport theft isn't realistic..."

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

### Validate File Uploads Like They're Hostile

NEVER trust anything the client says about an uploaded file. Validate the content, replace the name, and serve uploads so they can't execute.

The client's filename, extension, and Content-Type are all attacker-chosen. An upload feature that trusts them is a stored-XSS and code-upload feature.

- Allowlist file types by sniffing actual content (magic bytes via `file-type`, `python-magic`, or re-encoding images through a library), not by extension or the client's `mimetype` field. Reject anything outside the allowlist; never blocklist "dangerous" extensions and accept the rest.
- Treat SVG as code, not image: it executes scripts when served inline. Either reject it, sanitize it with a dedicated SVG sanitizer, or serve it only as `Content-Disposition: attachment`.
- Discard the original filename. Store under a server-generated name (`uuid4()` plus an extension you chose based on sniffed type); keep the user's name as display metadata only. This kills traversal, overwrite, and trick-extension (`invoice.pdf.exe`, null-byte) games at once.
- Store outside the web root (or in object storage), never in a directory where the web server might execute content. Serve via a handler or, better, a separate cookie-less domain (`usercontent.example.net`), with `Content-Type` set from your sniffed type, `X-Content-Type-Options: nosniff`, and `Content-Disposition: attachment` for anything not strictly needed inline.
- Enforce size limits at the parser level (multer `limits`, nginx `client_max_body_size`), and bound image dimensions before processing — decompression bombs cook servers.
- Never feed the upload's path or name into shell commands (thumbnailing via ImageMagick CLI etc.) by string interpolation; pass argument arrays.
- If the feature stores to S3-style object storage via presigned URLs, constrain the content type and size in the presigned policy, not just in the UI.

**Red flags that you're about to violate this:**
- "Multer already filters by mimetype, that's the validation..."
- "Checking the extension covers the realistic cases..."
- "SVGs are images, and we accept images..."
- "Keeping the original filename makes downloads friendlier..."
- "Serving from /uploads on our domain is simplest, it's all static files..."
- "Size limits can wait until someone actually abuses it..."

### Always Verify Webhook Signatures

NEVER process a webhook without verifying it came from the provider. Signature verification is part of the handler's skeleton, not a hardening step.

A webhook URL is public and guessable. Without verification it's an open API that anyone can use to mark orders paid, upgrade accounts, and feed your system fake events.

- Use the provider's SDK verification (`stripe.webhooks.constructEvent(rawBody, sigHeader, secret)`, GitHub's `X-Hub-Signature-256` HMAC check, Twilio's validator) before touching the payload. No SDK: compute the HMAC of the raw body with the shared secret and compare with a constant-time function, never `==`.
- Verification needs the raw bytes. Configure the route to receive them: `express.raw({type: 'application/json'})` on the webhook path before any JSON middleware, `request.get_data()` in Flask. If verification fails on valid-looking events, the body was parsed-and-reserialized upstream — fix the middleware order, do not remove the check.
- Reject on failure with 400 and log it; never "log a warning and process anyway."
- Check the timestamp where the scheme includes one (replay protection); make handlers idempotent on the event ID, since providers redeliver and attackers replay.
- Never decide trust from the payload's own fields (`"source": "stripe"`), the `User-Agent`, or IP ranges alone; those are optional defense in depth, not the control.
- Webhook secrets are credentials: from env/secret manager, distinct per environment, rotatable. Test-mode secrets differ from live — failing verification on test events usually means the wrong secret, not a broken library.
- These rules apply to every inbound automation callback: payment events, CI/CD hooks, messaging providers, OAuth/IdP back-channel calls, internal service hooks.

**Red flags that you're about to violate this:**
- "I'll get the event handling working first and add verification after..."
- "The signature check keeps failing, the library must be buggy, removing it for now..."
- "Nobody knows this URL, it's effectively private..."
- "The payload says it's from the provider, and it parses correctly..."
- "We can trust the provider's IP range instead of doing crypto..."
- "It's just a notification hook, worst case someone sends a fake notification..."
