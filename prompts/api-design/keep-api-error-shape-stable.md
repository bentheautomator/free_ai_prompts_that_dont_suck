---
title: Keep API Error Response Shape Stable
slug: keep-api-error-shape-stable
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops restructuring error bodies that clients parse to show messages and retry"
---

# Keep API Error Response Shape Stable

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from restructuring an API's error response body, breaking every client that parses errors to display messages or decide behavior.

**[Copy-paste ready version](../../install/keep-api-error-shape-stable.md)** — just the instruction block, no explanation.

## The Problem

Error bodies are the contract everyone forgets is a contract. An API returns `{"error": "Email already taken"}`; the AI introduces a centralized error handler and the shape becomes `{"errors": [{"code": "EMAIL_TAKEN", "message": "Email already taken", "field": "email"}]}`. Objectively richer. Arguably what the API should have shipped on day one. Also a breaking change for every consumer that reads `body.error` and now gets `undefined`.

The blast radius is sneaky because error parsing fails quietly. Frontends show "Something went wrong" instead of "Email already taken." Clients that switch on `body.error_code` stop matching and fall through to generic handling. A partner's retry logic that checked `body.error == "rate_limited"` retries nothing, or everything. The API still returns errors with the right status codes — it's only the part humans and programs read that went blank.

AI assistants restructure error shapes readily because error handling is exactly where codebases are messiest, and unifying it is a genuinely good instinct. The problem is the unification happens at the serialization boundary, where every inconsistent old shape is something some client already parses.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep API Error Response Shape Stable

NEVER change the structure of an existing endpoint's error response body. Clients parse error bodies by exact key — to display messages, match error codes, and decide whether to retry — and a restructured shape silently breaks all of it.

- Do not rename error keys (`error` → `message`), change types (string → array of objects), nest flat errors, flatten nested ones, or wrap existing shapes in an envelope, even to unify inconsistent handlers.
- Introducing a centralized error handler or middleware is fine only if it reproduces each endpoint's existing error shape exactly. "One consistent format" applied to shipped endpoints is a breaking change per endpoint.
- Enriching is allowed only additively: keep every existing key with its existing type and meaning, and add new keys alongside (`error` stays a string; add `error_detail` next to it).
- Machine-read fields like `code` or `error_code` are the most fragile part — clients switch on their exact values. Treat changing those values as seriously as changing the keys.
- If the user wants a unified error format, propose shipping it under a new API version or content negotiation, with the old shapes preserved until consumers migrate.

**Red flags that you're about to violate this:**
- "Every endpoint formats errors differently; I'll standardize them while I'm in here."
- "The new error middleware gives us a much richer structure for free."
- "Clients only care about the status code; the body format is internal."
- "I'm just wrapping the old message in an errors array — same information."
- "Structured error codes are strictly better than bare strings."

---

## Why It Works

1. **It establishes that error bodies are parsed, not just logged.** The AI's mental model of error responses is "text a developer reads"; naming message display, code matching, and retry decisions reclassifies them as machine contracts.
2. **It targets the centralized-handler move specifically**, which is the single most common vehicle for this breakage — the AI believes unification is the fix, and the instruction says unification *is* the break.
3. **It defines "additive" precisely for errors** (same keys, same types, new keys alongside), leaving no room to argue that wrapping or restructuring preserves the information.
4. **It elevates error-code values to contract status**, closing the loophole where the shape survives but the enum of codes changes underneath it.

## Origin

Asked to "clean up error handling" in a payments service, an assistant added exception middleware that emitted a uniform `{"errors": [...]}` array across forty endpoints, replacing a dozen ad-hoc shapes. The checkout frontend read `body.error` for user-facing messages and `body.code` for declined-card handling; both came back undefined, so every payment failure — including routine declines — rendered as a generic crash screen. Support volume tripled for two days while the team bisected a deploy that had touched "only error formatting."
