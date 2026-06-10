---
title: Use Obvious Placeholders in Doc Examples
slug: use-obvious-placeholders-in-doc-examples
category: documentation
tags: [universal, docs, security]
works_with: all
severity: high
one_liner: "Doc examples with realistic-looking keys and values readers mistake for real"
---

# Use Obvious Placeholders in Doc Examples

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents documentation examples containing realistic-looking credentials, IDs, and endpoints that readers copy as-is or scanners flag as leaks.

**[Copy-paste ready version](../../install/use-obvious-placeholders-in-doc-examples.md)** — just the instruction block, no explanation.

## The Problem

The AI writes an auth guide and, wanting the example to look real, generates `api_key = "sk_live_REALISTIC_LOOKING_KEY"`. It looks real because it's shaped exactly like a real key. Now three bad things are possible: a reader copies it verbatim and burns an hour on mysterious 401s; a secret scanner flags the repo and someone burns an afternoon proving it's fake; or — the genuinely scary one — the model reproduces a string pattern close enough to a real leaked key that nobody can prove it's fake. The same applies to realistic emails (`jsmith@gmail.com` belongs to an actual person), real-looking internal hostnames, and plausible customer IDs.

The opposite failure also bites: placeholders that are too subtle. `your-api-key` in a position where a base64-looking string is expected reads as a literal value to a skimming reader at 2am. People paste `<YOUR_KEY_HERE>` into production configs more often than anyone wants to admit, and "Bearer YOUR_TOKEN" has appeared in real request logs everywhere.

Models default to realistic examples because realism reads as quality. For example values, realism is the defect.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use Obvious Placeholders in Doc Examples

NEVER put realistic-looking secrets, credentials, emails, or identifiers in documentation examples. Every example value must be unmistakably fake at a glance and impossible to mistake for working configuration.

The problem: realistic example values get copied into real configs, flagged by secret scanners, and occasionally collide with actual people's data. Realism in example values is a bug, not polish.

Rules:
- Secrets and keys: use clearly-labeled placeholders in the project's existing convention, e.g. `<your-api-key>` or `YOUR_API_KEY`. Never generate a string matching a real provider's key format (`sk_live_...`, `AKIA...`, `ghp_...`, JWT-shaped blobs)
- Emails and domains: use reserved ones only: `user@example.com`, `example.org`, `*.example.net`. Never `@gmail.com` addresses or plausible company domains; those resolve to real inboxes and real sites
- IPs and hostnames: use documentation ranges (`192.0.2.x`, `198.51.100.x`, `203.0.113.x`) and `localhost`/`example.com` derivatives, not addresses that route
- IDs: make them readably fake (`usr_0000example`, `order_TEST123`), not statistically plausible
- Mark substitution points consistently: if the doc set uses `<angle-brackets>`, use those everywhere; mixing conventions makes some placeholders look literal
- Where a reader could plausibly paste the placeholder itself, add the one-line note: "replace `<your-api-key>` with the key from your dashboard"
- Never copy real values from the repo, env files, or logs into docs "as examples," even partially redacted

**Red flags that you're about to violate this:**
- "A realistic key makes the example clearer..."
- "I'll generate a random string in the right format..."
- "This email is obviously made up..." (it's somebody's)
- "I'll use the value from the .env file but change a few characters..."
- "Real-looking IDs make the response example believable..."
- "Nobody would actually copy-paste the placeholder..."

---

## Why It Works

1. **It optimizes for glance-distinguishability.** Readers and scanners both classify values by shape, in milliseconds. Values that are fake at the shape level (`<...>`, `example.com`, `192.0.2.1`) fail safe in every consumer: human, scanner, and copy-paste.

2. **It uses reserved namespaces that engineers already trust.** `example.com` and the documentation IP ranges exist precisely so example traffic and example mail can never hit anything real. Using them outsources safety to the infrastructure.

3. **It closes the format-mimicry path.** "Random string in the provider's format" is the worst of both worlds: triggers scanners, looks live, and could collide with leaked-key corpora. Banning the format, not just the value, removes the ambiguity entirely.

4. **It handles the too-subtle failure too.** Placeholder conventions plus the explicit replace-this note cover the 2am reader, who is the actual audience for every setup doc.

## Origin

A repo's AI-written webhook guide included an example secret formatted exactly like the provider's real signing secrets. The org's secret scanner quarantined the repo and paged security, who spent half a day confirming the string appeared in no vault and no provider account before declaring it synthetic. The same week, a separate user copied the guide's example endpoint, a plausible-looking domain that turned out to be registered, and sent several hundred webhook payloads to a stranger's server. Both incidents were fixed by the same one-line policy: nothing in docs may look real.
