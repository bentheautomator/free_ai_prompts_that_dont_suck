---
title: Never Tighten API Validation Silently
slug: never-tighten-api-validation-silently
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops stricter validation that rejects requests the API accepted yesterday"
---

# Never Tighten API Validation Silently

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding stricter request validation that starts rejecting payloads existing callers have been sending successfully for years.

**[Copy-paste ready version](../../install/never-tighten-api-validation-silently.md)** — just the instruction block, no explanation.

## The Problem

"Add proper validation" is a request AI assistants over-fulfill with enthusiasm. Asked to validate one new field, the assistant validates the whole payload: email regex on a field that previously accepted anything, max-length 255 on a free-text field, strict type coercion where `"42"` used to be accepted for an integer, `additionalProperties: false` so unknown keys — which were always tolerated — now fail the request. Every rule is individually reasonable. Collectively they redefine which requests are legal, retroactively.

The callers who break are the ones who were *in spec* yesterday. A CRM integration sends phone numbers with spaces; the new regex rejects them. A legacy client includes an extra metadata key it's always sent; `additionalProperties: false` bounces the whole payload. A form that submits numbers as strings — fine under loose coercion — now 400s. These aren't malformed requests being caught; they're the API's installed base colliding with a stricter definition of valid that nobody announced.

The AI tightens because validation is framed as defense, and more defense seems strictly better. What's missing from that frame is that an API's *de facto* contract is whatever it has been accepting — and tightening is contract change wearing a safety vest.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Tighten API Validation Silently

NEVER add validation to an existing endpoint that rejects requests it previously accepted. What an API has been accepting IS its contract — regardless of what the docs say — and stricter rules retroactively outlaw payloads that deployed callers send today.

- When asked to validate something specific, validate exactly that. Do not opportunistically add format checks, length limits, stricter type rules, or required keys to the rest of the payload "while you're in there."
- High-risk tightenings to avoid on shipped endpoints: format regexes on free-form fields (email, phone, postal codes), `additionalProperties: false` / forbidding unknown keys (tolerance for extras is part of the contract), disabling type coercion (`"42"` → 42), max lengths below what's been stored before, trimming/normalization changes that alter accepted values.
- Migrating to a validation library (Zod, Pydantic, Joi, Bean Validation) must reproduce the old acceptance behavior. The library's strict defaults are not the contract; the old handler's tolerance is. Configure permissiveness explicitly.
- The compatible path for genuinely-needed strictness: validate-and-log first (accept the request, log would-be rejections), review real traffic, then enforce by human decision — or enforce only in the next API version.
- If the user explicitly asks for strict validation on an existing endpoint, list which currently-accepted payload shapes will start failing, so they're choosing the breakage knowingly.

**Red flags that you're about to violate this:**
- "While adding this field's validation, I'll properly validate the whole request."
- "Rejecting unknown properties protects against typos — strictness is safety."
- "Any client sending an email without an @ deserves the 400."
- "The validation library's defaults are best practice; I'll keep them."
- "Stricter input validation can only improve data quality."

---

## Why It Works

1. **It defines the contract as observed acceptance, not documented intent**, removing the loophole where tightening is framed as "enforcing what was always meant."
2. **It separates the asked-for check from opportunistic ones** — the failure is almost always scope expansion around a legitimate one-field request, and the rule cuts at exactly that joint.
3. **It names library defaults as a contract hazard**, because validation migrations import strictness nobody chose, and the AI otherwise treats defaults as endorsed best practice.
4. **It supplies validate-and-log**, the standard professional path, so the AI's data-quality motive has a compatible outlet with evidence attached.

## Origin

Asked to "add validation for the new tax_id field," an assistant introduced a schema for the entire customer payload, including `additionalProperties: false`. A point-of-sale integration had always included a harmless `pos_terminal` key in its requests; every customer update from thousands of terminals began failing with a validation error naming a field nobody had touched. The integration vendor's support queue and the API team's on-call met in the middle two days later. The tax_id check itself — the actual task — was four lines and fine.
