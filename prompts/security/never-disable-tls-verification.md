---
title: Never Disable TLS Certificate Verification
slug: never-disable-tls-verification
category: security
tags: [universal, security, tls]
works_with: all
severity: critical
one_liner: "AI setting verify=False or rejectUnauthorized:false to silence SSL errors"
---

# Never Disable TLS Certificate Verification

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from turning off certificate validation to make an SSL error disappear.

**[Copy-paste ready version](../../install/never-disable-tls-verification.md)** — just the instruction block, no explanation.

## The Problem

An HTTPS request fails with `CERTIFICATE_VERIFY_FAILED` or `UNABLE_TO_VERIFY_LEAF_SIGNATURE`. The AI's fastest path to a green checkmark is `verify=False` in Python requests, `rejectUnauthorized: false` in Node, `NODE_TLS_REJECT_UNAUTHORIZED=0` in the environment, or `curl -k`. The error vanishes. The AI declares victory. Your application now accepts any certificate from anyone, which means any machine between you and the server can read and modify your traffic, including the credentials in it.

AI assistants do this because the certificate error looks like an obstacle rather than a security control doing its job. The error message itself often suggests the bypass — Stack Overflow's top answer for nearly every TLS error is "disable verification" — so the insecure fix is heavily represented in training data. And it always works, in the sense that the request goes through.

The real cause is almost always fixable: a missing corporate root CA, an incomplete certificate chain on the server, an expired cert, or a wrong hostname. Each has a correct fix that keeps verification on.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It enumerates the exact escape hatches.** The AI knows a dozen spellings of "turn off TLS" across languages and tools. Listing them by name (`verify=False`, `-k`, `NODE_TLS_REJECT_UNAUTHORIZED=0`) blocks each one specifically instead of relying on the AI to generalize from a principle.

2. **It replaces the bypass with a diagnostic path.** The AI reaches for the bypass because it has no other next step. Giving it `openssl s_client` and the four common root causes means the secure path is also the path of least resistance.

3. **It pre-empts the "it's just dev" rationalization.** Dev code with `verify=False` gets copied to prod, and dev machines carry real credentials. Naming the thought before it happens makes the AI recognize it as a red flag rather than a justification.

4. **It handles the corporate-proxy case explicitly.** This is the single most common legitimate-looking trigger, and it has a clean fix (trust the corporate CA) that most assistants never suggest unprompted.

## Origin

A developer behind a corporate TLS-inspecting proxy asked an AI assistant to fix a failing `pip`-installed SDK call. The assistant patched the HTTP client with `verify=False`, the call succeeded, and the patch shipped in a utility module reused by six services. Months later a security review found every outbound API call in the platform — including ones carrying OAuth tokens — had been running without certificate validation. The actual fix was one environment variable pointing at the corporate CA bundle.
