---
title: Validate TLS Certificates Before Cutover
slug: validate-tls-certs-before-cutover
category: devops
tags: [universal, devops, dns]
works_with: all
severity: critical
one_liner: "Swapping a TLS cert without checking chain, SANs, or old-cert consumers"
---

# Validate TLS Certificates Before Cutover

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from installing a certificate that breaks every client the moment it goes live, or deleting one that production still serves.

**[Copy-paste ready version](../../install/validate-tls-certs-before-cutover.md)** — just the instruction block, no explanation.

## The Problem

Certificate work has a uniquely unforgiving shape: the change is binary, instant, and fails for every client simultaneously. An AI asked to "renew the cert" or "switch to the new certificate" will attach the new cert to the listener and call it done — without checking that the SAN list actually covers every hostname the endpoint serves (the renewed cert is often missing the one subdomain that mattered, or covers `example.com` but not `*.example.com`), without including the intermediate chain (browsers paper over missing intermediates via AIA fetching; mobile apps, curl, and language HTTP clients do not — so the site "works in Chrome" and fails everywhere that counts), and without confirming the private key matches the cert it's deploying.

The cleanup side is just as dangerous: deleting the "old" certificate from ACM or the secrets store while a listener, a CDN distribution, or a forgotten internal endpoint still references it. Some platforms block in-use deletion; plenty don't, and some fail at the next deploy instead, long after the deletion looked safe.

Assistants treat certs as opaque blobs to be swapped. They're contracts with every client, and the contract terms — names, chain, validity window, key match — are all checkable in advance with openssl one-liners the AI knows but doesn't run.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Validate TLS Certificates Before Cutover

NEVER install, replace, or delete a TLS certificate without validating it first and identifying everything that uses the old one. Cert mistakes fail all clients at once, and a deleted in-use cert can take an endpoint down at the next restart.

Before attaching a new cert:
- Check coverage: `openssl x509 -in cert.pem -noout -text | grep -A1 'Subject Alternative Name'` — every hostname the endpoint serves must be listed or wildcard-covered. `example.com` and `*.example.com` are different entries.
- Check validity dates and that the key matches: compare `openssl x509 -noout -modulus | openssl md5` against `openssl rsa -noout -modulus | openssl md5`.
- Include the full intermediate chain in the deployed bundle. Verify post-deploy with `openssl s_client -connect host:443 -servername host` and confirm `Verify return code: 0` — a browser check is not sufficient, because browsers repair missing intermediates and real clients don't.
- Prefer staged validation: attach to a staging listener or test port first, verify with real client libraries, then cut over.

Before deleting or letting an old cert lapse:
- Enumerate consumers: load balancer listeners, CDN distributions, API gateways, internal services, webhook mTLS configs. In AWS: `aws acm describe-certificate --certificate-arn ... --query 'Certificate.InUseBy'`.
- Keep the old cert available until the new one is verified in production; cert rollback should be re-attaching, not re-issuing.
- Never disable cert validation anywhere (clients, health checks) to make a cutover "work." A verification failure is the system telling you the cutover is broken.

**Red flags that you're about to violate this:**

- "The cert was issued for this domain, the SANs will be fine..."
- "It loads in my browser check, ship it..."
- "The old cert is expired-ish anyway, deleting it cleans things up..."
- "I'll skip the chain file, most clients fetch intermediates themselves..."
- "Renewal is routine, it doesn't need a verification step..."

---

## Why It Works

1. **It replaces "browser-tested" with protocol-tested.** The browser's chain-repair behavior is the single biggest source of false confidence in cert work; mandating `openssl s_client` verification closes the gap between "works in Chrome" and "works."

2. **It makes coverage a checklist, not an assumption.** SAN mismatches are the most common renewal failure and are fully detectable in advance with one command the rule spells out.

3. **It treats deletion as a dependency problem.** "Old cert" implies unused; requiring consumer enumeration converts that implication into a query with an actual answer.

4. **It preserves the rollback artifact.** Keeping the old cert attached-able until the new one is proven mirrors the deploy-rollback discipline — re-issuing under incident pressure is the worst possible time to do CA paperwork.

## Origin

A routine renewal replaced a wildcard cert with a freshly issued one that listed the apex and `www` but not the wildcard — the issuance request had been hand-built and nobody diffed the SANs. Browsers on the marketing site were fine; every mobile app call to `api.` failed TLS validation at once. The fix was a re-issue with the correct SANs, but the diagnosis ate ninety minutes because the first three checks were all done in a browser, which had no complaints about the only hostnames it was shown.
