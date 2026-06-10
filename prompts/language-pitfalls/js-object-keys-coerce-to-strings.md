---
title: JS Object Keys Coerce to Strings
slug: js-object-keys-coerce-to-strings
category: language-pitfalls
tags: [universal, javascript]
works_with: all
severity: high
one_liner: "Stops object key coercion from merging numbers, objects, and ids into one slot"
---

# JS Object Keys Coerce to Strings

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents plain objects from silently stringifying every key, so `obj[1]` and `obj["1"]` collide and object keys all become `"[object Object]"`.

**[Copy-paste ready version](../../install/js-object-keys-coerce-to-strings.md)** — just the instruction block, no explanation.

## The Problem

Plain JavaScript objects have exactly one key type: string (plus symbols nobody passes by accident). Every other key is coerced. `obj[1]` and `obj["1"]` are the same slot. `obj[true]` is `obj["true"]`. And the spectacular one: use an object as a key — `cache[user] = profile` — and every user coerces to the literal string `"[object Object]"`, so the entire cache is one entry that each write overwrites. Reads "work" too: they all return whatever was written last, which makes the bug look like a data mix-up instead of a key collision.

There are quieter versions. Numeric string keys can change iteration order (integer-like keys are iterated first, in ascending numeric order), so a lookup table keyed by id renders in a different order than it was built. And mixing `Map`-style thinking with object syntax — `lookup.set` on an object, or `obj.size` — produces undefined-method errors that at least fail loudly.

Assistants fall into this when porting from Python (`dict` keys can be any hashable type, and `d[1]` and `d["1"]` are different entries) or Java (`HashMap<User, Profile>` is routine). The object-as-dictionary idiom is so dominant in JS training data that the model reaches for `{}` even when the keys are not strings.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### JS Object Keys Coerce to Strings

NEVER use a plain object as a dictionary when the keys are anything other than strings you control. Object keys are coerced to strings: `obj[1] === obj["1"]`, and any object key becomes `"[object Object]"`, collapsing all entries into one.

- Non-string keys (numbers you must keep distinct from strings, objects, DOM nodes, class instances): use `Map`. `Map` compares keys by identity/SameValueZero with no coercion: `map.get(1)` and `map.get("1")` are different entries.
- Wrong: `const seen = {}; seen[node] = true` — every node coerces to `"[object Object]"`. Right: `const seen = new Set()` or `new Map()`.
- Keying by entity: `cache[user]` is the collapsed-cache bug. Use `cache.set(user, value)` (identity) or key by a real scalar: `cache[user.id]`.
- If you key an object by numeric ids, know that `Object.keys` returns strings (`"42"`, not `42`) and integer-like keys iterate in ascending numeric order regardless of insertion order. If either fact would surprise the consuming code, use a `Map` (which preserves insertion order and key types).
- `WeakMap`/`WeakSet` when object keys should not prevent garbage collection (caches, metadata side-tables).
- Plain objects remain fine for fixed, known string keys (config, JSON-shaped records). The rule is about dynamic dictionaries.

**Red flags that you're about to violate this:**

- "An object literal is the lightweight way to build a lookup table."
- "The keys are user ids, numbers work fine as keys." (They become strings; fine until someone compares.)
- "I'll index by the object itself, it's unique."
- "Map is overkill, this is just a small cache."
- "Insertion order will be preserved like in Python dicts."
- "JSON.stringify the key and it's effectively the same thing." (Stringify is order-sensitive and slow; say so if you truly need it.)

---

## Why It Works

1. **It breaks the Python/Java dict equivalence.** The model's prior says dictionaries take arbitrary keys; stating the coercion rule with `obj[1] === obj["1"]` replaces that prior with the actual JS semantics.
2. **It names the `"[object Object]"` collapse explicitly.** This failure has no error message and no exception — only a description of the symptom lets the model recognize it as a bug class rather than mysterious data corruption.
3. **It maps each key type to a concrete structure.** Map, Set, WeakMap, and `user.id` cover the realistic cases, so "use the right structure" never decays into "use `{}` anyway."
4. **It scopes the rule.** Plain objects for fixed string keys stay legal, so the model doesn't rewrite every config literal into a Map and discredit the rule.

## Origin

A feature-flag service cached per-organization evaluation results in a plain object keyed by the org record: `cache[org] = flags`. Every org coerced to `"[object Object]"`, so all orgs shared one cache slot — whichever org evaluated last donated its flags to everyone for the next sixty seconds. Premium features flickered on for free-tier users in production for two days; the cache "hit rate" metric looked fantastic the whole time.
