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
