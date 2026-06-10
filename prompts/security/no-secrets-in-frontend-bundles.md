---
title: Never Put Secrets in Frontend Code or Bundles
slug: no-secrets-in-frontend-bundles
category: security
tags: [universal, security, secrets]
works_with: all
severity: critical
one_liner: "AI exposing server keys via NEXT_PUBLIC and VITE_ env prefixes"
---

# Never Put Secrets in Frontend Code or Bundles

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from shipping API keys to every visitor's browser via client env vars and bundled code.

**[Copy-paste ready version](../../install/no-secrets-in-frontend-bundles.md)** — just the instruction block, no explanation.

## The Problem

A frontend needs to call a paid API, and the key is `undefined` in the browser. The AI knows this dance: rename the env var to `NEXT_PUBLIC_OPENAI_API_KEY`, or `VITE_STRIPE_SECRET`, or `REACT_APP_DB_PASSWORD`, and it works! Of course it works. Those prefixes are an instruction to the bundler to inline the value into the JavaScript shipped to every visitor. The "environment variable" is now a string literal in a public file, one `view-source` or DevTools network tab away, and bots scrape deployed bundles for exactly these patterns.

The prefix convention inverts its own appearance: it looks like configuration hygiene while functioning as publication. AI assistants fall for it constantly because the error ("process.env.X is undefined in the browser") has the prefix rename as its top documented fix, and the fix is correct — for values that are supposed to be public, like an analytics ID. The model doesn't distinguish "publishable" from "secret" keys; it distinguishes "works" from "doesn't." The same failure wears other costumes: calling a paid API directly from React with the key in an Authorization header, embedding service-role database keys in a mobile app ("it's compiled"), or hardcoding an admin token in a JS constant because "it's minified."

Anything that must stay secret cannot be in code that runs on devices you don't own. The call has to move server-side.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It renames the prefix to what it does.** "Publication mechanism, not configuration" reframes the exact mental step where the AI goes wrong; the rename stops being a fix and starts being the leak.

2. **It answers the driving error with the right fix.** "Undefined in the browser" needs a resolution; providing the thin-backend-route pattern means the AI has a working alternative at the moment of temptation.

3. **It teaches the publishable/secret taxonomy.** `pk_` vs `sk_`, anon vs service_role: most violations come from not knowing which keys are designed to be public. The classification step converts a vague fear into a checkable property.

4. **It extends "client" beyond the browser.** Mobile and Electron apps trigger the "it's compiled" rationalization; including them removes the loophole the rule would otherwise leave.

## Origin

A hackathon-pace feature called an LLM API straight from the React app; the assistant resolved the env var error with the documented `VITE_` prefix and the demo shipped to production. A scraper found the key in the bundle within two days, and the team learned about it from a usage-spike alert and a four-figure bill for someone else's inference workload. The replacement was a twenty-line serverless function, the rotation took five minutes, and the invoice took longer.
