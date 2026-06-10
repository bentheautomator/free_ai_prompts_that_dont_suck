---
title: Never Fetch User-Supplied URLs Server-Side Unchecked
slug: no-unvalidated-server-side-fetches
category: security
tags: [universal, security, injection]
works_with: all
severity: critical
one_liner: "AI building SSRF holes via webhook testers, importers, and URL previews"
---

# Never Fetch User-Supplied URLs Server-Side Unchecked

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents server-side request forgery: your backend fetching internal endpoints on an attacker's behalf.

**[Copy-paste ready version](../../install/no-unvalidated-server-side-fetches.md)** — just the instruction block, no explanation.

## The Problem

"Add a link preview feature." "Let users import from a URL." "Build a webhook tester." Each of these ends with the server fetching a URL a user typed, and the AI writes exactly that: `requests.get(url)`, `fetch(userUrl)`, done. The server, though, stands somewhere the user doesn't: inside the VPC, next to `http://169.254.169.254/latest/meta-data/` (cloud credentials via the metadata service), `http://localhost:6379` (Redis), internal admin panels, and every microservice that "doesn't need auth because it's internal." SSRF turns your URL-fetching feature into the attacker's proxy into all of it. It's how one of the most expensive cloud breaches on record started.

AI assistants almost never defend this unprompted, and their first defense when asked is hostname string-matching — block "localhost," block "169.254" — which loses to decimal IP encodings (`http://2130706433/`), IPv6 (`[::1]`), DNS names that resolve to internal addresses, and redirects: the validated URL returns a 302 to the metadata service and the HTTP client follows it automatically. DNS rebinding defeats even honest resolve-then-check implementations if the check and the fetch resolve separately.

Real mitigation is layered: resolve and validate the IP, pin the connection to that IP, disable or re-validate redirects, and ideally egress through a dedicated proxy with its own policy.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It names the metadata service as the target.** `169.254.169.254` is the concrete prize that makes SSRF real to the model; abstract "internal resources" doesn't change generated code, a specific IP does.

2. **It invalidates string-matching as a defense category.** The AI's instinctive fix is hostname blocklists; declaring resolve-pin-connect as the minimum bar prevents the confident half-fix.

3. **It covers redirects and rebinding explicitly.** These are the two bypasses that defeat sincere first implementations, and neither occurs to a model unprompted.

4. **It widens the feature list.** SSRF hides in webhook testers and PDF renderers that don't pattern-match as "fetching user URLs"; enumerating them triggers the rule where it's actually needed.

## Origin

A "test your webhook" button did exactly what the assistant was asked: POSTed a sample payload to whatever URL the customer entered and displayed the response body. A customer entered the cloud metadata URL and read back the instance's IAM credentials in the response viewer, then used them to list private storage buckets. The remediation added IP-range validation, redirect re-checking, response truncation, and an egress proxy; the incident review noted the feature had shipped in an afternoon and the fix took three weeks.
