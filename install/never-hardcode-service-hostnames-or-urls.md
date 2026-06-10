### Never Hardcode Service Hostnames or URLs

NEVER embed hostnames, ports, or full URLs for services, databases, brokers, or third-party APIs as string literals in application code. The address of a dependency is environment configuration, and a literal that is correct on one machine is wrong on every other one.

- Read every dependency address from configuration: environment variables, a config file selected per environment, or service discovery. `PAYMENTS_API_URL=http://localhost:8081` belongs in `.env.development`, not in the code.
- Define each address exactly once, in a config module, and import it. Five call sites reading `process.env.PAYMENTS_API_URL` directly is five chances for a typo'd fallback.
- Fail fast at startup if a required address is missing. Do not default to localhost in the code (`process.env.API_URL || "http://localhost:3000"`) — that fallback silently activates in any misconfigured environment, including production.
- This covers more than HTTP: database hosts, Redis endpoints, Kafka bootstrap servers, SMTP relays, webhook callback URLs your service hands out, and CORS origins.
- Keep the scheme and port in the config value too. Hardcoding `https://` + configurable host breaks local TLS-less setups; hardcoding `:8081` breaks everything else.
- Provide a `.env.example` documenting every required variable so new environments are configured by checklist, not by archaeology.

**Red flags that you're about to violate this:**
- "I'll just hardcode it for now and we can extract it later."
- "It's localhost in dev anyway, this makes the example runnable."
- "It's an internal service, the address never changes."
- "I'll add a sensible localhost fallback so it works out of the box."
- "It's only used in this one place."
- "The staging URL is fine here, this code only runs in staging."
