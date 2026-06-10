---
title: Never Deserialize Untrusted Data With Unsafe Loaders
slug: no-unsafe-deserialization
category: security
tags: [universal, security, injection]
works_with: all
severity: critical
one_liner: "AI using pickle.loads or yaml.load on data an attacker can touch"
---

# Never Deserialize Untrusted Data With Unsafe Loaders

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from feeding external data into deserializers that can execute code.

**[Copy-paste ready version](../../install/no-unsafe-deserialization.md)** — just the instruction block, no explanation.

## The Problem

Some deserializers don't just parse data, they instantiate arbitrary objects, and instantiating arbitrary objects is remote code execution with a file format. Python's `pickle.loads` will run an attacker's `__reduce__` payload. `yaml.load` without `SafeLoader` constructs arbitrary Python objects from a config file. PHP's `unserialize`, Java's `ObjectInputStream`, Ruby's `Marshal.load`, and Node's `node-serialize` all share the disease. An AI asked to "cache this object," "parse this YAML," or "read the session from the cookie" will reach for these because they're the obvious, native, handles-everything tool.

The failure compounds because the AI's mental model of "untrusted" is too narrow. A Redis cache is untrusted if anything else can write to it. A cookie is untrusted by definition, even if your server wrote it, because the client sends it back. A message queue, an S3 object, a file a user uploaded, a value from another team's service: all attacker-influenceable in realistic threat models. The AI sees "data we stored ourselves" and waves it through.

The safe versions are sitting right there: `yaml.safe_load` is the same line with four extra characters. JSON covers most serialization needs with no code-execution semantics at all.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Deserialize Untrusted Data With Unsafe Loaders

NEVER use a deserializer capable of instantiating arbitrary objects on data that crosses a trust boundary. Default to JSON or another data-only format.

Unsafe deserialization is remote code execution: the payload runs during parsing, before your validation code ever sees the data.

- Banned on external or attacker-influenceable data: `pickle.loads`, `yaml.load` (use `yaml.safe_load`), `eval`/`ast.literal_eval` confusion (only `literal_eval` is safe, and prefer JSON anyway), PHP `unserialize`, Java `ObjectInputStream` on raw input, Ruby `Marshal.load`, `node-serialize`/`serialize-javascript` round-trips.
- "Attacker-influenceable" is broad: cookies and anything client-supplied, cache entries (Redis/memcached) if any other process writes them, queue messages, uploaded files, cross-service payloads, and database blobs other code paths can write. Your own storage is not a trust boundary if inputs ever flow into it.
- Default serialization format: JSON. For schemas/performance use protobuf, msgpack (without object extensions), or CBOR. These parse data, not constructors.
- Pickle is acceptable only for same-process or fully internal artifacts (e.g., a local model file you built), and even then prefer formats like safetensors where they exist. Never unpickle anything downloaded.
- If a session/cookie must round-trip server data, sign it (HMAC, or the framework's signed-cookie mechanism) and verify before parsing, and still keep the payload JSON.
- When you encounter existing `yaml.load` or `pickle.loads` in code you're editing, switch to the safe variant or flag it; do not propagate the pattern to new call sites.

**Red flags that you're about to violate this:**
- "Pickle handles arbitrary Python objects, JSON would need a schema..."
- "We wrote this cache entry ourselves, so it's trusted data..."
- "yaml.load is what the older docs show, and it works..."
- "The cookie is ours, the client just stores it for us..."
- "It's an internal queue, only our services publish to it..."
- "I'll validate the object right after deserializing it..."

---

## Why It Works

1. **It corrects the order-of-operations illusion.** "I'll validate after parsing" fails because the exploit fires during parsing. Stating that explicitly dismantles the AI's standard safety plan.

2. **It expands the trust boundary to match reality.** Caches, queues, and cookies all read as "our data" to an AI. The enumerated list reclassifies them, which is where the actual disagreement lives.

3. **It makes the safe path the default, not the exception.** "Default to JSON" turns the decision into opt-out: the AI must justify an unsafe loader rather than remember to avoid one.

4. **It allows the legitimate pickle cases narrowly.** A flat ban gets ignored the first time pickle is genuinely appropriate; scoping it to same-process artifacts keeps the rule credible.

## Origin

To make sessions "richer," an assistant serialized a user object into a cookie with pickle and read it back on each request, base64 and all. The cookie was not signed. A pentester crafted a pickle payload with a `__reduce__` calling `os.system` and had a shell on the web tier from an unauthenticated request. The replacement was a signed JSON session cookie, which the framework had supported natively the entire time.
