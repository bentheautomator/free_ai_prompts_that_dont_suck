---
title: Load Config Once, Not Per Request
slug: load-config-once-not-per-request
category: performance
tags: [universal, performance, io]
works_with: all
severity: high
one_liner: "Stops re-reading and re-parsing the same config file on every request"
---

# Load Config Once, Not Per Request

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from re-reading and re-parsing static files (config, schemas, templates, secrets, ML models) on every request instead of once at startup.

**[Copy-paste ready version](../../install/load-config-once-not-per-request.md)** — just the instruction block, no explanation.

## The Problem

`def handler(req): config = yaml.safe_load(open("config.yml"))`. A settings parser invoked at the top of every route. A translations JSON read per page render. A 400MB ML model deserialized per prediction call. The file hasn't changed since deploy; the work of reading and parsing it is identical every single time; the process does it anyway, per request, forever. At 300 requests per second, a 3ms parse is nearly a full CPU core spent re-learning the same facts, plus disk I/O that competes with everything else on the box.

AI assistants do this because putting the load next to the use is the locally-clearest code, and because helper functions like `get_config()` get written stateless ("no globals, no side effects") and then innocently called from hot paths. Each call site looks cheap; nobody is looking at the sum. In dev, with one user and an SSD, the cost rounds to zero.

The fix is among the cheapest in all of performance work — read once at startup, hold the parsed result in memory — which makes paying this cost on every request genuinely embarrassing once someone finally straces the process and watches it `open("config.yml")` four hundred times a second.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Load Config Once, Not Per Request

NEVER read or parse a static resource (config file, schema, template, translation bundle, certificate, ML model, prompt file) inside a per-request or per-item code path. Anything that doesn't change between requests is loaded and parsed once, at startup or first use, and the parsed result held in memory.

A 3ms parse done at 300 rps is most of a CPU core spent re-learning the same file. The work is identical every time; pay for it once.

- Load at module init or app startup into a constant, or behind a once-guard (lazy singleton, `functools.cache` on a zero-arg loader, `sync.Once`). Handlers consume the in-memory object.
- The transitive version counts: a `get_settings()` helper that opens a file is per-request I/O no matter how clean it looks at the call site. Check what your helpers do, not just what your handler does.
- Same rule for derived artifacts: compiled templates, parsed JSON schemas, deserialized models, loaded wordlists. Parse once, reuse the parsed form.
- If the file genuinely must be re-readable without redeploy, that's a refresh policy, not per-request reads: reload on a timer (every 30s), on a file-watch event, or on an admin signal. Decide and state the staleness tolerance; "read it every time" is the policy of not deciding.
- Startup loading also fails loudly at the right time: a missing or malformed config kills the deploy at boot instead of failing request number one in production.
- Verify at the syscall layer: run a handful of requests and confirm via strace/lsof/debug logging that the file opens once, not once per request.

**Red flags that you're about to violate this:**
- "Reading it each time guarantees we always have the latest values."
- "File reads are fast, the OS caches it."
- "Avoiding module-level state keeps the function pure."
- "It's just a small YAML file."
- "Startup loading makes the code harder to test."
- "The helper already exists, I'm just calling it."

---

## Why It Works

1. **It splits 'fresh' from 'every time'.** The AI's main justification is freshness; forcing an explicit refresh policy with a stated staleness tolerance shows that per-request reads were never a freshness strategy, just an unexamined default.
2. **It pierces the helper-function veil.** Most instances hide behind an innocent-looking `get_config()`; requiring a check of what helpers *do* catches the transitive case that call-site review misses.
3. **It reframes startup failure as a feature.** "Malformed config kills the boot, not request number one" gives the AI a correctness reason to prefer the fast pattern, aligning two incentives instead of trading them.
4. **It verifies with opens, not opinions.** "The file opens once" is a binary, strace-checkable fact immune to fixture-size effects.

## Origin

A latency investigation on a payments gateway found p50 fine and p99 awful. The trail led to a `load_keys()` helper that opened and PEM-parsed a certificate bundle — called by the signature verifier, on every request, since the day it was written. Under load, those file opens contended on the same disk as the access logs; p99 spikes lined up perfectly with log-flush intervals. Hoisting the parse to startup cut p99 by 60% and reduced the service's disk reads by, per the dashboard, approximately all of them.
