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
