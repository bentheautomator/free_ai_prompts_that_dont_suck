---
title: Never Hardcode Service Hostnames or URLs
slug: never-hardcode-service-hostnames-or-urls
category: backend
tags: [universal, backend]
works_with: all
severity: medium
one_liner: "Keeps localhost:3000 out of code that has to run anywhere but your laptop"
---

# Never Hardcode Service Hostnames or URLs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents hardcoded `localhost` and environment-specific URLs from breaking every environment that isn't the one they were written on.

**[Copy-paste ready version](../../install/never-hardcode-service-hostnames-or-urls.md)** — just the instruction block, no explanation.

## The Problem

Ask an assistant to call the payments service and you'll get `fetch("http://localhost:8081/charge")`. It's not wrong, exactly — that's where the payments service is running *right now, on this machine*. The assistant optimizes for the code working in the current session, and in the current session, localhost is the truth. So localhost gets baked into the source, sometimes in four different files, sometimes with the staging URL in one of them because that's what was in the assistant's context when it wrote that particular function.

Then the code leaves the laptop. In Docker, `localhost` is the container itself, and the call dials the service's own empty port. In staging, it's a connection refused at 2 a.m. during the deploy. Worst case, it half-works: most call sites read config, but one forgotten hardcoded URL points staging at the production payments API, and your test suite starts charging real cards. Scattered literals also mean every new environment — a preview deploy, a new region, a colleague's machine — requires a code change and a grep session instead of an environment variable.

This is among the most common AI-generated defects because the failure is invisible at write time. The code runs. The demo passes. The string is a landmine with a deployment-shaped trigger.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It countermands the assistant's write-time incentive.** The assistant is rewarded by code that runs in the current session; the rule explicitly states that session-correct addresses are deployment-incorrect.
2. **It bans the localhost fallback, which is the sneakiest variant.** `|| "localhost"` passes review as defensive coding while guaranteeing that misconfiguration fails silently instead of loudly at startup.
3. **It centralizes, which makes drift impossible.** One config module means an environment is right or wrong everywhere at once — no more "four of five call sites updated."
4. **It enumerates non-HTTP addresses.** Assistants that learn the rule for API URLs still hardcode Redis hosts; the explicit list closes that gap.

## Origin

A team shipped a feature where four service calls read the gateway URL from config and a fifth — added late, by an assistant, in a separate file — hardcoded the staging hostname. It passed staging perfectly. In production, one endpoint quietly wrote orders into the staging database for nine days. Reconciling which orders were real involved three engineers and a spreadsheet nobody enjoyed.
