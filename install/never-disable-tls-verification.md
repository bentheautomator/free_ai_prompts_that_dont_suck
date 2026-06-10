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
