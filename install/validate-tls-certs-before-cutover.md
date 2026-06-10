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
