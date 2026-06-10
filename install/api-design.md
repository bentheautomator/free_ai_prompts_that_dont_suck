### Add API Pagination Additively

When adding pagination to an existing endpoint, the default behavior for requests WITHOUT pagination parameters MUST remain "return everything," exactly as before. A default page size silently truncates every existing client to page one — a 200 response with most of the data missing and no error.

- Paginate only when the caller opts in (sends `page`, `limit`, `cursor`, or similar). No params means the full, unwrapped, original response.
- Do not change the response shape for legacy requests. If paginated responses gain an envelope (`{"data": [], "meta": {}}`), only opted-in requests get it; param-less requests keep the bare array.
- Do not impose a max page size that's smaller than the current full result, and do not let framework pagination helpers apply their default limits to param-less requests.
- Silent truncation is worse than slowness. If the unpaginated query is the performance problem, say so and let the user choose between a versioned endpoint, a deprecation window with client outreach, or accepting the cost temporarily.
- The same applies in reverse contexts: never lower an existing default page size or maximum limit — clients sized their loops to the current values.

**Red flags that you're about to violate this:**
- "Defaulting to 50 per page is standard; clients can pass a higher limit if they want."
- "Returning the entire table was always a bug — I'm fixing it."
- "The framework paginator handles missing params with a sensible default."
- "Existing callers will still get a 200, so this is backward compatible."
- "Anyone consuming this much data should have been paginating already."

### Additive-Only GraphQL Schema Changes

NEVER remove or rename anything in a shipped GraphQL schema: fields, types, enums, interfaces, unions, or query/mutation names. Deployed client queries reference these by exact name, and a single unknown field fails the entire query — one rename can blank a whole app screen, including in client versions that can never be updated.

- Schema evolution is addition-only: add new fields next to old ones, add new types, add new enum values (cautiously), add new queries/mutations. The old names keep resolving.
- To replace a field, add the successor, mark the old one `@deprecated(reason: "Use displayName")`, and leave it functional. Deprecated-but-working is the correct end state of this change; actual removal is a later, human-scheduled step driven by field-usage metrics.
- In code-first schemas (type-graphql, Strawberry, graphene, Nexus, gqlgen), resolver and class renames ARE schema renames. Before renaming any resolver-adjacent identifier, check whether it surfaces in the SDL; if it does, pin the schema name explicitly while renaming the code.
- Changing a field's return type (`String` → custom scalar, object → union, singular → list) breaks selection sets and generated client types just like a removal. Same rule: new field, deprecate old.
- If the user explicitly asks for a removal, ask whether field-level usage metrics confirm zero traffic, and note that unlike REST, clients fail at query validation — partial tolerance is not available.

**Red flags that you're about to violate this:**
- "These two types are nearly identical; merging them simplifies the schema."
- "I renamed the resolver method, but that's just a code-level refactor."
- "The schema is versionless, so cleanups like this are how GraphQL evolves."
- "Our own frontend doesn't query this field — I checked the .graphql files."
- "The deprecation has been there for ages; clearly it's time to delete."

### Alias Renamed API Query Params

NEVER rename a query parameter on an existing endpoint without keeping the old name working as an alias. Unknown query params are silently ignored, so callers using the old name don't get errors — they get *unfiltered results*, which is usually the most dangerous possible response.

- A renamed filter param fails open: `?user_id=7` on an endpoint that now reads `userId` returns every user's data with a 200. For scoping, date-range, and `since`-style params, silent ignoring means data over-exposure or full-history reprocessing, not a visible bug.
- If a rename is justified, accept both names: read the new param, fall back to the old one, and document the old as deprecated. The alias stays until a human retires it with usage data.
- The same applies to changing a param's *value format* (IDs to UUIDs, dates to a new format, comma-separated to repeated params): old-format values that no longer match return empty or unfiltered results, not errors. Keep parsing the old format alongside the new.
- Framework migrations are the high-risk moment: binding annotations and handler-signature names often *are* the param names. After migrating, diff the full set of accepted param names per endpoint against the old code.
- Where a previously-honored param can no longer be honored at all, prefer rejecting requests that send it (explicit 400 with a pointer to the replacement) over silently ignoring it — a loud failure beats quietly unfiltered data.

**Red flags that you're about to violate this:**
- "I'm aligning all query params with the camelCase convention."
- "The handler signature changed, so the param name follows automatically."
- "Old callers will notice immediately if their param stops working."
- "It still returns 200 for old-style requests, so it degrades gracefully."
- "Nobody passes that param anyway — it's not used in any of our calls."

### Freeze API Default Query Behavior

NEVER change what an existing endpoint returns when a parameter is omitted. The no-parameter request is its own contract: every existing caller sends it, and a new or changed default rewrites all of their results at once without a single error.

- When adding a new filter, flag, or scope parameter to an existing endpoint, its default MUST reproduce the endpoint's current behavior exactly — even when that default looks wrong. If the endpoint returned archived rows before, `include_archived` defaults to `true`.
- Never flip an existing default (`include_deleted`, `expand`, `status`, default date ranges) on a shipped endpoint, and never narrow an endpoint's implicit scope (all records → current user's records) outside an explicit, user-approved breaking change.
- A request with no params returning a 200 is not evidence of compatibility. The contract is the *content*: same records, same scope, same filters as before the change.
- If the current default is genuinely dangerous or wrong, present the fix as a breaking change: new API version, new endpoint, or a deprecation window with announced default-flip date. Not a silent edit.
- After adding any parameter, state in your summary what a parameter-less request returned before and after. They must match.

**Red flags that you're about to violate this:**
- "Excluding archived items by default is what most callers would expect."
- "The old default was a footgun; defaulting to the safe value fixes it."
- "Callers who want the old behavior can just pass the flag."
- "I'm only adding a parameter — omitting it is handled gracefully."
- "Scoping the list to the current user is more secure, so it's an improvement."

### Freeze API ID Formats

NEVER change the type or format of identifiers in an existing API: integer → UUID, number → string, unprefixed → prefixed, or any change to length, casing, or structure. IDs are the only API values consumers store long-term — in their databases, URLs, and caches — so a format change breaks not just parsing but every reference already handed out.

- Both JSON type and format are frozen: `4821` (number) → `"4821"` (string) breaks typed deserializers even though the digits match. `"4821"` → `"ord_4821"` breaks everything that stored the bare value.
- Old IDs must resolve forever. Even with an internally migrated ID scheme, every endpoint that accepts an ID must keep accepting the previously-issued format and look it up correctly. An ID is a permanent ticket, not a current-schema artifact.
- Database/internal migrations (int PK → UUID) are acceptable only if the serialization boundary continues exposing and accepting the old external format — via a mapping table or dual-key lookup. The external ID and the storage key are allowed to be different things; keep them different.
- If a new format is genuinely required externally (e.g., enumeration concerns), expose it additively: a new `uuid` or `public_id` field next to `id`, with old lookups still honored, and flag the consumer-migration plan to the user.
- Numeric IDs approaching JavaScript's safe-integer limit are a real problem with the same answer: add a string twin field; do not mutate the existing field's type.

**Red flags that you're about to violate this:**
- "Sequential integer IDs are an enumeration risk; switching to UUIDs fixes it."
- "Returning IDs as strings is safer for JavaScript clients, so it's an improvement."
- "Prefixed IDs like cus_123 are industry best practice."
- "The migration maps every old ID to a new one, so nothing is lost."
- "Consumers treat IDs as opaque — format shouldn't matter to them."

### Freeze API List Sort Order

NEVER change the order in which an existing list endpoint returns items — including "undocumented" or accidental orderings. Consumers infer order guarantees from observed behavior: they take the first element as latest, terminate sync loops on order, and display results as received. A changed order produces wrong data with a 200, never an error.

- Do not remove or alter ORDER BY clauses during query optimization, ORM migrations, or cleanup — even ones that look redundant. If the old query had no explicit ordering but returned a stable de facto order, add an explicit ORDER BY that *preserves* the observed order rather than leaving it to a new query plan.
- Changing databases, indexes, or pagination internals can silently reorder results. After such changes, compare result order on real data against the previous behavior.
- Alphabetical, relevance, or "more sensible" default orderings are new features: ship them behind a `sort=` parameter, and make the parameter's absence return the historical order.
- Within paginated endpoints, ordering is also what keeps pages consistent — changing it mid-flight breaks consumers walking pages, duplicating or skipping records across the boundary.
- If the user explicitly wants a new default order, note which consumer patterns break (first-element-as-latest, order-based sync termination, display order) and suggest the sort-param route with the default unchanged.

**Red flags that you're about to violate this:**
- "This ORDER BY isn't required by anything in the code — removing it speeds up the query."
- "Alphabetical order is more user-friendly for this list."
- "The API never documented an order, so no order is guaranteed."
- "The new query returns the same rows; order is an implementation detail."
- "Consumers should sort client-side if they care about order."

### Freeze API Numeric Field Types

NEVER change the JSON type or representation of an existing numeric field: integer ↔ float, number ↔ string, precision/rounding, or notation. Consumers deserialize numbers into declared types — `int`, `Long`, `Decimal` — and a representation change either throws in their parser or silently shifts their math. JSON's single number type is an illusion; the consumer's type is the contract.

- An integer field emits integers forever: `5`, never `5.0`. Internal changes that introduce floats (division, unit conversion, column type changes, ORM casts) must be rounded or cast back to int at the serialization boundary.
- Do not convert numeric fields to strings — even for the good reasons (decimal precision, JS big-integer safety). The fix for those is a NEW string field (`price_decimal`, `id_str`) alongside the unchanged numeric one, so consumers opt in.
- Preserve emitted precision and rounding: a field that has always shown two decimal places keeps showing two. Consumers compare, checksum, and re-display these values verbatim.
- Serializer swaps can change number rendering wholesale — scientific notation thresholds, trailing-zero handling, max precision. After any serializer change, diff real payloads for numeric fields specifically; "the values are mathematically equal" is not the test, byte equality is.
- If the user asks to change a numeric representation in place, identify the consumer classes that break (strict typed parsers throw; loose ones mis-compute) and steer to the additive-field path.

**Red flags that you're about to violate this:**
- "Using a proper Decimal type end-to-end is strictly more correct for money."
- "String-encoding large IDs protects JavaScript clients from precision loss."
- "5 and 5.0 are the same number; no consumer could care."
- "The extra decimal places only add precision — nothing is lost."
- "The new serializer renders numbers more accurately by default."

### Freeze API Timestamp Formats

NEVER change the serialization format of an existing date or time field in an API response, request, or webhook. The format — epoch vs ISO, seconds vs milliseconds, timezone suffix, precision — is part of the contract, and every consumer has a parser built for exactly the current form.

- Forbidden conversions on shipped fields include: epoch ↔ ISO 8601, seconds ↔ milliseconds, adding/removing fractional seconds, adding/removing timezone offsets or `Z`, changing `2024-06-10` ↔ `2024-06-10T00:00:00`, and changing locale-formatted dates in any direction.
- Watch the passengers: new serializers, DateTime library upgrades, ORM swaps, and language-idiomatic defaults all reformat dates silently. After such changes, diff a real serialized payload against the old format field-by-field.
- The worst variants don't error — they shift. Seconds read as milliseconds land in 1970; a `Z` added to a local time moves every event by the UTC offset. Treat "the value still parses" as insufficient: it must parse to the same instant via the consumer's *old* code.
- Want ISO? Add a new field (`created_at_iso`) beside the old one, or serialize the new format only under a new API version. Never in place.
- If the user explicitly requests an in-place format change, state that every consumer's date parsing breaks or silently shifts, and recommend the additive path.

**Red flags that you're about to violate this:**
- "ISO 8601 is the standard; epoch timestamps are a legacy artifact."
- "The new serializer formats dates properly out of the box — I'll keep its default."
- "I'm adding timezone info, which makes the data more correct, not less."
- "It's still the same instant in time, just written differently."
- "Milliseconds are more precise, and precision can't hurt anyone."

### Freeze Webhook Payload Contracts

NEVER change the structure, field names, event type strings, or envelope of an existing webhook payload. Webhook subscribers are external parsers you cannot see, and unlike API callers they cannot retry or re-request: an event their handler can't parse is an event lost forever.

- Frozen elements include: the event name/type string (`order.completed`), every payload key and its type, the envelope structure (`data` wrapper, `meta`, top-level vs. nested), ID and timestamp formats, and how absence is expressed (null vs. omitted).
- Subscribers route on the event type string with exact matching. Renaming an event, even trivially, means their switch statement silently falls through — delivery still returns 200, so no alarm fires anywhere.
- Evolve additively only: add new optional fields to existing payloads, or introduce entirely new event types alongside old ones. To restructure, publish a new event version (`order.completed.v2`) and keep emitting v1 until subscribers migrate.
- Webhook payload builders look like internal code because nothing in the repo reads their output. That is exactly backwards: zero internal consumers means 100% of consumers are external.
- If the user explicitly asks to change a webhook's shape, state that all current subscribers will mis-parse or drop the events with no error visible on either side, and recommend the versioned-event path with a migration window.

**Red flags that you're about to violate this:**
- "I'll rename the event to match the naming convention of the new events."
- "Wrapping the payload in a data envelope makes all our webhooks consistent."
- "Nothing in this codebase parses these payloads, so the shape is free to change."
- "Subscribers get the events over HTTP — they'll see the new fields immediately."
- "It's our outbound data; we control the format."

### Keep API Array vs Object Shapes

NEVER change whether an existing API field or response body is a single object or an array — in either direction. Object-expecting code reads properties off arrays and gets undefined; array-expecting code maps over objects and throws; typed deserializers reject the payload entirely. There is no consumer that tolerates this change by accident.

- When a singular concept becomes plural in the data model (one address → many addresses), keep the shipped singular field exactly as it was — populated with the primary/first value — and ADD a plural field alongside it (`address` stays an object; `addresses` is the new array).
- Never unwrap a one-element array to a bare object ("it can only ever be one") or wrap a bare object into an array ("for consistency with the list endpoint"). Top-level response shapes count double: array ↔ object at the root breaks literally every caller's first line of parsing.
- NEVER make the shape conditional on cardinality — object when one result, array when many. This is the worst variant: it passes every single-record test and fails on the first multi-record response in production.
- Watch serializer defaults: some XML-to-JSON and ORM-relation serializers emit an object for one child and an array for several. Pin the shape explicitly.
- If the user explicitly asks to change a field's cardinality in place, state that both strict and loose consumers break immediately, and propose the keep-singular-add-plural path or a new API version.

**Red flags that you're about to violate this:**
- "Users can have multiple addresses now, so the field should be an array."
- "It returns at most one record — the array wrapper is pointless."
- "Returning an array only when there are multiple results handles both cases neatly."
- "I'll make the detail endpoint match the list endpoint's shape."
- "Consumers can check Array.isArray — it's one line of defensive code."

### Keep API Empty Result Contract

NEVER change how an existing endpoint represents "no results" or "not found": the status code (200 vs. 404) and the body shape (`[]` vs. `null` vs. `{}` vs. error body) are both frozen, even when the current choice contradicts REST convention. Consumers are calibrated to the exact current signal, and their empty-case handling is the least-tested code they have.

- If a search endpoint returns 404 when nothing matches, it keeps returning 404 — even though `200 []` is the better design. If a lookup returns `200` with `null`, that stays too. Correctness of convention does not outrank deployed calibration.
- Both halves matter: changing `404` → `200 []` silently disables consumers' error-path-based empty handling; changing `200 null` → `404` makes their HTTP clients throw on a routine state. Neither direction is the safe one.
- Watch for indirect flips: ORM changes (`.get()` raising vs. returning None), framework error handlers, and "fix inconsistent not-found behavior" cleanups all change the empty contract without the word "empty" appearing in the task.
- Distinguish the cases when *building new* endpoints — empty collection (`200 []`), missing singular resource (`404`), and existent-but-empty resource (`200` with empty value) — and pick deliberately, because whatever ships becomes permanent.
- If the user asks to standardize empty behavior across existing endpoints, enumerate which endpoints change which signal, and recommend doing it only behind a new API version.

**Red flags that you're about to violate this:**
- "Returning 404 for an empty search result is just wrong; empty list is the standard."
- "I'll make all the not-found cases consistent across the API."
- "null is a poor representation of absence — an empty object is cleaner."
- "Clients should be handling both 200-empty and 404 anyway."
- "This is a one-branch change in the handler; it barely touches anything."

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

### Keep API Response Envelope Stable

NEVER add, remove, or restructure the envelope of an existing endpoint's response — no wrapping bare payloads in `{"data": ...}`, no unwrapping existing envelopes, no renaming envelope keys, no converting a top-level array to an object or vice versa. Moving every field one level deep (or shallower) breaks all consumers at once, exactly like renaming every field simultaneously.

- A mixed API — some endpoints enveloped, some bare — is each endpoint's individual contract, not a defect to unify. Consistency is for endpoints that don't exist yet.
- Top-level array ↔ top-level object is the sharpest version: `response.map(...)` versus `response.data.map(...)` cannot both work, so there is no client that survives the change by accident.
- Beware one-line blast radius: global response interceptors, serializer base classes, and "standardize API responses" middleware change every endpoint's envelope in a single edit. Any such change must explicitly exempt all shipped endpoints.
- Adding *siblings inside* an existing envelope (a new `meta` key next to `data`) is additive and fine. Adding the envelope itself is not. Note: if the response is currently a top-level array, there is nowhere compatible to put metadata — that's a new-version problem, not a wrapping problem.
- If the user wants a uniform envelope, apply it to new endpoints and new API versions, or offer it via opt-in (header or query param) on existing ones, with the default shape unchanged.

**Red flags that you're about to violate this:**
- "Half the endpoints wrap responses and half don't — I'll standardize them."
- "Wrapping in a data key now gives us room for metadata later."
- "The envelope is pure boilerplate; unwrapping simplifies every client."
- "One interceptor fixes the response format everywhere at once."
- "No field names changed, so consumers are unaffected."

### Keep API Success Status and Body Stable

NEVER change the success status code of an existing endpoint, and NEVER remove or empty a success response body that previously had content. Deployed clients check exact codes (`status === 200`) and unconditionally parse bodies; "more correct" codes like 201 or 204 break both.

- Do not upgrade `200` to `201` on creation endpoints, `200` to `202` for async work, or `200`-with-body to `204 No Content`, no matter how strongly REST convention recommends it.
- Removing a response body is a breaking change even when the body looks redundant. Clients call `.json()` on it, read IDs from it, and log it. An empty 204 body makes those parsers throw.
- The reverse also holds: do not start returning a body where none existed, if clients might treat unexpected content as an error — and never change `204` back to `200` on a shipped endpoint.
- New endpoints you create from scratch should use the correct codes from day one. The freeze applies to endpoints that have already shipped.
- If the user asks for the "correct" codes on an existing endpoint, make the change only after stating that any client checking exact status values or parsing the body will break, and offer to gate it behind a new API version.

**Red flags that you're about to violate this:**
- "This is a creation endpoint, so it should obviously return 201."
- "The response body just echoes the request — nobody needs it."
- "Returning 204 for DELETE is the standard; I'll align with it."
- "Any sane client checks the 2xx range, not the exact code."
- "I'm only touching the success path, which is the safe part."

### Keep Unused API Response Fields

NEVER remove a field from an API response because it appears unused. A code search proves nothing: response fields are consumed by HTTP clients outside this repository, and grep cannot see them.

- "No references in the codebase" is not evidence a response field is dead. It is the expected state for a field whose only consumers are external — which is most of them.
- Do not delete fields during refactors, serializer rewrites, DTO consolidation, or "remove dead code" tasks. Carry every existing field through, even ones that look vestigial, misnamed, or always-null.
- If a field is expensive to compute or genuinely believed dead, the safe sequence is: log or instrument its access where possible, mark it deprecated in docs/OpenAPI, announce a sunset date, then remove it in a deliberate, human-approved change. Not as a side effect of cleanup.
- When rewriting a handler or serializer, diff the old response shape against the new one field-by-field before finishing. Any missing key is a breaking change unless the user explicitly asked for its removal.
- If the user explicitly asks to drop a field, comply, but say clearly that any external consumer reading that key will break, and offer the deprecation path.

**Red flags that you're about to violate this:**
- "Grep shows nothing reads this field, so it's safe to remove."
- "This field is always null anyway; no one could be using it."
- "The new serializer is cleaner without these legacy fields."
- "I'm consolidating two DTOs and only keeping the fields that overlap."
- "The frontend in this repo doesn't use it, and that's the only client."

### Lock GraphQL Nullability and Arguments

NEVER change nullability markers (`!`) on existing GraphQL fields, and NEVER add required arguments or required input-type fields to shipped queries and mutations. Both directions of a nullability flip break consumers, and required additions invalidate every deployed operation that predates them.

- Nullable → non-null (`String` → `String!`) is a runtime bomb: the first resolver null triggers non-null propagation, erroring the parent selection or the whole response for all clients because of one bad record.
- Non-null → nullable (`String!` → `String`) breaks generated client types in every consumer that runs codegen, and deployed clients built against non-null crash on the first null they were promised would never come.
- New arguments on existing fields/queries must have defaults or be nullable. New fields on existing input types must be optional. Deployed operations are frozen text — often in persisted-query allowlists — and cannot retroactively send anything.
- Tightening an input the resolver genuinely needs is done in the resolver: validate at runtime, return a typed error for new violations, and keep the schema signature stable. Schema-level tightening waits for a new field or schema version.
- If asked to "make the schema match reality" by adding `!`, first confirm the data can never be null (including legacy rows and failure paths), and present the flip to the user as a breaking change for codegen consumers regardless.

**Red flags that you're about to violate this:**
- "This field is never actually null, so marking it non-null just documents reality."
- "Codegen consumers will simply regenerate their types — that's what codegen is for."
- "The mutation needs this argument now; old clients should be passing it anyway."
- "Loosening to nullable can't break anyone — it accepts strictly more."
- "It's a one-character schema change."

### Match Existing API Naming Conventions

When adding new endpoints, fields, or parameters to an existing API, ALWAYS follow the conventions the API already uses — even where they differ from REST best practices or your preferred style. The incumbent convention is correct by definition; an objectively nicer style that's inconsistent makes the API worse and manufactures pressure for a future breaking "cleanup."

- Before designing anything new, read the existing surface: route files, OpenAPI/schema definitions, or a handful of existing handlers. Extract the live conventions for: path style (plural/singular, nesting depth, kebab/camel segments), field casing (snake_case vs camelCase), parameter names (`page`/`per_page` vs `offset`/`limit` vs `cursor`), ID field naming (`id` vs `user_id` vs `uuid`), timestamp field naming and format, envelope shape, and error body shape.
- Copy those conventions exactly. If the API is RPC-style (`/getUserOrders`), new endpoints are RPC-style. If it paginates with `?page=`, the new list endpoint paginates with `?page=` — not the cursor scheme you'd choose green-field.
- When the existing API is itself inconsistent, match the dominant or most recent pattern, and say which one you followed and why in your summary.
- Do not "fix" existing names to match the new endpoint, and do not introduce a better convention as a beachhead ("new endpoints will use the new style going forward") unless the user explicitly establishes that policy.
- If the incumbent convention is genuinely problematic (e.g., it collides with a framework constraint), raise it as a question before building, rather than unilaterally deviating.

**Red flags that you're about to violate this:**
- "I'll use REST conventions for the new endpoint even though the API is RPC-style."
- "camelCase is the JSON standard, whatever the older fields do."
- "This is a fresh endpoint, so it's a chance to start doing things right."
- "Cursor pagination is better, and only the new endpoint will have it."
- "I didn't check the other routes — list endpoints are pretty standard anyway."

### Never Add Required API Request Headers

NEVER make a request header mandatory on an existing endpoint — neither a new header nor stricter enforcement of an existing one. A header introduced today is, by definition, sent by zero existing callers; requiring it rejects the entire installed base in one deploy, and middleware-level enforcement does it across every endpoint simultaneously.

- New headers (`X-Request-ID`, `X-Client-Version`, `X-Tenant-ID`, `Idempotency-Key`, custom auth-adjacent metadata) must be optional with a server-side default: generate the request ID, infer the tenant from the existing auth context, treat absent idempotency keys as non-idempotent requests — exactly as the endpoint behaved before.
- Do not tighten existing header handling on shipped endpoints: stricter `Content-Type` matching, newly-enforced `Accept` negotiation, or `User-Agent` requirements all reject callers whose requests worked yesterday.
- Middleware multiplies the mistake. A required-header check added globally converts one feature's requirement into an API-wide breaking change. Scope any enforcement to new endpoints only.
- The legitimate path to a required header: accept-and-log absence first, measure which callers omit it, notify them, and enforce on a deadline by human decision — or require it only in the next API version.
- If the user explicitly asks to require a header, state the consequence precisely — every existing caller fails immediately with 4xx — and propose the optional-with-default or log-then-enforce path.

**Red flags that you're about to violate this:**
- "The tracing system needs a request ID, so requests without one are invalid."
- "Requiring the client version header lets us handle old clients properly."
- "Strict Content-Type checking is just correct HTTP."
- "I'll enforce it in middleware so no endpoint can forget it."
- "It's one header — clients can add it in a minute."

### Never Change API Field Semantics

NEVER change what an existing API field means while keeping its name: its units (cents vs. dollars, seconds vs. milliseconds), its basis (net vs. gross, before vs. after tax), its reference frame (UTC vs. local), or its inclusion rules (what counts toward a total). Semantic changes are invisible to every schema check and type system — consumers keep parsing successfully and start computing wrong values, which in money fields means real incorrect charges.

- The unit IS the contract. If `amount` has been integer cents, it is integer cents forever. Refactoring internal money handling to decimal dollars is fine only if the serializer still emits cents.
- Changing what a computed field includes (`total` gaining shipping, `price` becoming tax-inclusive, `count` starting to include soft-deleted rows) is a semantics change even though no unit changed. Consumers reconcile against these numbers.
- If the new meaning is needed, give it a new name: `amount_decimal`, `total_with_tax`, `duration_ms` — added alongside the old field, which keeps its old meaning. A new name forces consumers to consciously adopt the new semantics; reusing the old name silently swaps meaning under them.
- During refactors of calculation or unit-handling code, trace each changed value to the serialization boundary and confirm the emitted number is identical for identical inputs. A golden-file comparison on real payloads catches what no type check can.
- If the user explicitly asks to change a field's meaning in place, state that consumers have no way to detect the change and will compute wrong values until manually updated — this is the strongest case for versioning that exists.

**Red flags that you're about to violate this:**
- "Storing money as cents is a legacy pattern; decimals are cleaner end to end."
- "I normalized all durations to milliseconds for consistency."
- "The total should obviously include tax — I'm correcting the calculation."
- "Same field, same type, same name — the response shape is untouched."
- "Any consumer will notice the values look different and adapt."

### Never Delete API Endpoints Based on Grep

NEVER delete, unregister, or stop serving an API endpoint because no code in this repository calls it. Zero internal references is the normal, expected state of a public endpoint — its callers are external HTTP clients that no code search can see.

- This covers every form of removal: deleting the handler, removing the route registration, dropping it from the router, commenting it out, or excluding it during a framework migration or router rewrite.
- Evidence that does NOT justify removal: no internal callers, no references in the frontend, no mention in recent commits, "legacy" or "old" or "deprecated" in the name, an empty-looking handler.
- Evidence that COULD justify removal — and only a human can confirm it: access logs showing zero traffic over a long window, a completed deprecation process with announced sunset, or the user explicitly confirming no external consumers exist.
- When migrating frameworks or rewriting routing, enumerate every route the old code served and verify the new code serves all of them. A route lost in migration is a deletion.
- If the user asks to remove an endpoint, ask whether external consumers were checked (logs, API gateway metrics, partner docs), state that removal 404s every external caller immediately, and suggest a 410-with-sunset-header deprecation period instead of an instant 404.

**Red flags that you're about to violate this:**
- "Nothing in the codebase calls this route, so it's dead."
- "It's named /legacy/ — clearly it was meant to be removed."
- "I searched the frontend too; no fetch calls hit this path."
- "The new router covers all the endpoints that actually matter."
- "Removing it shrinks the attack surface, so deletion is the safe choice."

### Never Flip API Field Nullability

NEVER cause an existing API response field that was always non-null to start returning null, and never change how absence is expressed (null vs. omitted key vs. empty string) for any shipped field. Consumers parse these fields without guards, into non-optional types and NOT NULL columns; the first null is a production exception in code you cannot see.

- A field's observed behavior is its contract. If it has always been present and non-null, treat it as `required, non-nullable` even if no schema says so.
- Refactors that introduce nulls without anyone deciding to: inner joins becoming left joins, lookups returning null instead of raising, new entity subtypes lacking the value, `Optional` return types propagating to the serializer. Check each new code path for what it serializes into old fields.
- Do not toggle serializer absence settings (`omit_empty`, `exclude_none`, `NON_NULL` inclusion) on existing payloads. `null`, missing key, and `""` are three distinct shapes to consumers; pick whichever the endpoint already uses and keep it.
- If a new case genuinely has no value for the field, prefer a non-breaking placeholder consistent with the field's type and meaning, or exclude such records from the old endpoint — and raise the contract question to the user explicitly.
- Relaxing in the other direction (nullable → always present) is safe. The dangerous direction is the only direction this rule restricts.

**Red flags that you're about to violate this:**
- "Returning null here is cleaner than throwing for the missing-profile case."
- "The field is null only in a rare edge case, so it barely counts."
- "exclude_none makes the payloads smaller with no downside."
- "Consumers should be doing null checks anyway; that's on them."
- "The schema never said non-nullable, so null was always allowed."

### Never Make Optional API Fields Required

NEVER change an optional request field to required on an existing endpoint. Every caller built while the field was optional legitimately omits it, and the change rejects all of them with 4xx errors on requests that were valid yesterday.

- Do not add `required`, remove `Optional[...]`, drop a default, or mark a field non-nullable in a request schema (JSON Schema, OpenAPI, Pydantic, Zod, protobuf, GraphQL input types) unless the field was already enforced as required at runtime.
- When formalizing a loosely-validated handler into a schema, mirror the *old runtime behavior*: a field the old code tolerated missing must be optional in the new schema, even if the new code uses it.
- If the business logic now needs the field, handle absence instead of rejecting it: apply a server-side default, infer it, or branch — and surface "consider requiring this in the next API version" to the user as a decision, not an edit.
- The safe direction is one-way: required → optional is compatible; optional → required is breaking. New fields you add to existing endpoints must always be optional or defaulted.
- If the user explicitly asks to require the field, comply, but state that every existing caller omitting it will start receiving errors, and suggest a deprecation window or versioned rollout.

**Red flags that you're about to violate this:**
- "This field is logically mandatory — a record without it makes no sense."
- "The new validation library defaults to required, and that's the safer default."
- "All the example payloads in the tests include it, so everyone sends it."
- "Making it required catches bad data earlier, which is strictly an improvement."
- "I'm just making the schema match how the new code actually uses the field."

### Never Remove API Enum Values

NEVER rename, remove, re-case, or merge an enum or status value that appears in API responses, requests, or webhooks. Consumers compare these as exact strings; a changed value doesn't error, it falls through their switch statements into default branches with unintended behavior.

- The exact serialized string is the contract: `shipped` ≠ `SHIPPED` ≠ `Shipped`. Casing normalization, spelling fixes (`cancelled` → `canceled`), and convention alignment (`pending_review` → `PENDING_REVIEW`) are all breaking changes to a string matcher.
- Do not merge "duplicate" states. Two values that mean the same thing to you are two distinct branches in consumer code; collapsing them reroutes one of those branches without warning.
- Renaming the enum member in code is fine only if the *serialized* value is pinned (e.g., `SHIPPED = "shipped"`). When refactoring enums, check what actually leaves the building — including the framework's default enum serialization, which often emits the member name.
- For request enums, keep accepting every value you ever accepted; map old inputs to new internals server-side. For response enums, keep emitting the value consumers expect.
- Adding new enum values to responses is allowed but is a soft break for consumers with exhaustive matching — mention it in your summary so the user can communicate it.
- If a value truly must go, the path is: announce, map server-side from old to new for a deprecation window, then remove by human decision. Never as part of a cleanup diff.

**Red flags that you're about to violate this:**
- "I'm normalizing all status values to uppercase to match the enum convention."
- "These two statuses are redundant — consolidating them simplifies the state machine."
- "It's a one-letter spelling fix; no reasonable client breaks on that."
- "I updated the enum and the database migration, so the change is complete."
- "Status strings are internal vocabulary; the API just happens to expose them."

### Never Rename API Endpoint Paths

NEVER rename, re-nest, re-case, or pluralize the URL path of an existing endpoint. A shipped path is hardcoded in external clients, configs, and saved tooling; renaming it turns every one of those references into a 404 that is indistinguishable from the endpoint never having existed.

- This includes every flavor of improvement: RPC-to-REST conversion (`/getUserOrders` → `/users/{id}/orders`), pluralization (`/order` → `/orders`), casing (`/userProfile` → `/user-profile`), re-nesting under new prefixes, and "fixing" inconsistent segment names.
- Updating all callers inside the repository proves nothing — the callers that break are the ones you cannot grep.
- If a better path is warranted, add it as an alias: register the new route AND keep the old route serving identical behavior (same handler), or return 301/308 redirects from the old path if all known clients follow redirects on the relevant methods (many HTTP clients do not follow redirects for POST/PUT by default — verify before relying on this).
- The old path stays until a human retires it through a deprecation process with usage metrics. "Both routes work" is the correct end state of your change, not an interim mess to clean up.
- Path *parameters* count too: changing `/orders/{order_number}` to resolve by internal ID instead of order number breaks every stored URL even though the route pattern looks identical.
- If the user explicitly asks for a rename, deliver it as alias-plus-new-path by default and say why; only remove the old route if they confirm no external callers exist.

**Red flags that you're about to violate this:**
- "This endpoint name doesn't follow REST conventions like the rest of the API."
- "I updated every fetch call in the codebase to the new path."
- "Singular /order was clearly a mistake — all the other resources are plural."
- "A redirect would be overkill; clients should just use the new URL."
- "I'm reorganizing the routes under a cleaner prefix structure."

### Never Rename API Response Fields

NEVER rename a field in an API response, even if the new name is more consistent, more idiomatic, or objectively better. A field name in a shipped response is a contract with consumers you cannot see: mobile apps, partner integrations, scripts, and pipelines that parse it by exact name.

- Do not rename fields to match casing conventions (`user_id` → `userId`), fix typos (`recieved_at` → `received_at`), or improve clarity (`amt` → `amount`). All of these break deserialization in every existing client.
- If a better name is genuinely needed, add the new field alongside the old one and return both. Mark the old field deprecated in docs/OpenAPI. Removal happens later, by a human, on a deprecation schedule — not in this change.
- Updating the repo's own tests, types, and clients does not make a rename safe. The consumers that matter are the ones not in this repository.
- Internal variable names, database columns, and private DTOs can be renamed freely — the rule applies only at the serialization boundary, the moment a name appears in a response body.
- If the user explicitly asks to rename a response field, do it, but state plainly that it is a breaking change for any external consumer and suggest the add-alongside-and-deprecate path.

**Red flags that you're about to violate this:**
- "While I'm here, I'll make the field names consistent with the rest of the API."
- "I updated every usage in the codebase, so nothing is broken."
- "It's just a casing change, clients probably handle both."
- "This field name is a typo; fixing it is obviously correct."
- "The frontend in this repo is the only consumer."

### Never Swap API Pagination Schemes In Place

NEVER replace an endpoint's existing pagination scheme (offset/limit, page/per_page, cursor, Link headers) with a different one on the same endpoint. Consumers implement paging as an algorithm — request, read the paging fields, loop — and changing the scheme breaks the loop, often into infinite repetition or silent single-page results.

- Existing pagination params must keep working with their existing semantics: `page=3` returns the third page, `offset=100` skips 100, forever. Ignoring an old param is worse than rejecting it.
- Existing paging fields in the response (`total`, `total_pages`, `has_more`, `next_url`) must keep appearing with correct values. Clients use them as loop-termination conditions; removing one creates infinite loops.
- Introduce a better scheme additively: accept `cursor` alongside `page`, return `next_cursor` alongside `total_pages`, and let new clients opt in. Or ship the new scheme on a new versioned endpoint.
- Cursor formats are also contracts once shipped: do not change their encoding or invalidate outstanding cursors, since clients persist them mid-pagination and across job runs.
- If supporting both schemes is genuinely infeasible, present that to the user as a breaking-change decision requiring a version bump and consumer migration, not something to fold into this diff.

**Red flags that you're about to violate this:**
- "Offset pagination doesn't scale; cursor-based is the correct approach here."
- "I'll map the old page param onto the new system approximately."
- "total_count was expensive to compute and the new scheme doesn't need it."
- "Clients just follow next links, so the underlying scheme is invisible to them."
- "This fixes the deep-pagination timeout, which is what the user really wants."

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

### No Side Effects in API GET Endpoints

NEVER implement an endpoint that creates, modifies, or deletes state behind GET (or HEAD). The HTTP contract marks GET as safe, and real infrastructure acts on that promise: email link scanners pre-fetch URLs, browsers prefetch on hover, proxies retry freely, and crawlers walk every route. A mutating GET will be triggered by machines, repeatedly, with no human intent.

- State changes go behind POST, PUT, PATCH, or DELETE. This includes the deceptively read-like ones: marking notifications read, recording views or analytics on the server, "tracking" opens, logging someone out, regenerating a token, advancing a workflow.
- Email-link actions (confirm, approve, unsubscribe) must not mutate on the GET itself: serve a page whose button issues the POST, or follow the established one-click pattern where the mutation rides a POST. Link scanners *will* fetch the URL before the user does.
- Do not bend the rule for convenience ("easier to test in a browser"), for webhook receivers (receiving data is a POST), or for "harmless" mutations — retried and prefetched harmless mutations stop being harmless.
- If you find an existing mutating GET, do not silently convert it to POST either — existing callers use GET. Add the POST route, keep the GET temporarily as deprecated, and flag the migration to the user.
- Reads with incidental non-observable bookkeeping (cache warming, last-accessed metrics) are acceptable; anything a user or another system can observe as changed is not.

**Red flags that you're about to violate this:**
- "It's just a confirmation link — a GET is the simplest thing that works."
- "This makes it easy to test by pasting the URL in a browser."
- "Marking it as read is barely a mutation."
- "No crawler will ever find an internal admin route."
- "I'll add the side effect to the existing GET so we don't need a new endpoint."

### Pin API Serializer Config

NEVER change global serializer or framework settings that affect how existing API responses are rendered: property naming strategies, null/empty-field inclusion, date/time formats, enum rendering, key ordering with semantic effect, or pretty/compact structure changes that alter content. One config line rewrites every endpoint's wire format at once — it is the largest possible breaking change hidden in the smallest possible diff.

- Treat these as frozen once an API has shipped: naming policy (`SNAKE_CASE`/`CamelCase` strategies), `omit_empty`/`exclude_none`/`NON_NULL` inclusion, global date formats, enum-as-name vs enum-as-value, number-as-string flags.
- When upgrading or swapping serialization libraries, the new library must be configured to reproduce the OLD wire format exactly — not its own defaults, and not the new version's "improved" defaults. Migration guides list behavior changes; check them against your payloads.
- Verify by golden-file diff: capture real serialized responses from several representative endpoints before the change and byte-compare (or key/structure-compare) after. "The tests pass" is meaningless when the tests serialize with the same config you just changed.
- Scope any genuinely-wanted new convention to new surface area only: a separate serializer instance for new endpoints or the next API version. Global config changes apply to history, and history has consumers.
- If the user asks for an API-wide format change, spell out that this re-renames or re-shapes every field of every response for every consumer, and propose the versioned or opt-in route.

**Red flags that you're about to violate this:**
- "The framework's new default naming strategy is what the config should have been all along."
- "One config line is much cleaner than annotating every DTO."
- "I'm swapping serializers, but they're functionally equivalent."
- "Dropping null fields shrinks payloads — pure win."
- "All the serialization tests still pass after the upgrade."

### Preserve API Error Status Codes

NEVER change the status code an existing endpoint returns for an existing error condition, even if a different code is more semantically correct. Clients branch on exact status codes: retry logic, cache invalidation, and error display are all keyed to the codes this endpoint already returns.

- Do not "fix" a 404 to a 400, a 500 to a 422, a 403 to a 404, or any other swap on a shipped error path. Correctness per the HTTP spec does not outweigh the behavior of deployed clients.
- A status code may look wrong and still be load-bearing: clients retry on 5xx but not 4xx, evict caches on 404, and refresh tokens on 401. Changing the code changes all of that behavior at once.
- New error conditions you are adding may use whatever code is most appropriate — the freeze applies only to conditions that already exist.
- If a code is genuinely harmful (e.g., a 200 that hides failures), flag it to the user as a breaking change and propose rolling it out behind an API version or an opt-in header, not as a silent edit.
- When refactoring a handler, list every (condition → status) pair the old code produced and verify the new code produces the identical mapping before finishing.

**Red flags that you're about to violate this:**
- "404 is technically wrong here; the resource path is valid, so 400 fits better."
- "The new framework's default error handler returns 422, which is more standard anyway."
- "Clients should be checking the error body, not the status code."
- "I'm normalizing all the not-found cases to one consistent code."
- "It's an error path — nobody depends on the exact failure code."

### Preserve PUT vs PATCH Semantics

NEVER change whether an existing update endpoint replaces the full resource or merges partial fields — regardless of which verb it uses and regardless of what the HTTP spec says that verb should do. Consumers are calibrated to observed behavior: flipping merge → replace makes their partial requests erase data; flipping replace → merge breaks their ability to clear fields by omission. Both flips corrupt data silently.

- A PUT that has always merged keeps merging. A PATCH that has always replaced keeps replacing. Spec-correcting a shipped endpoint's update semantics is a data-corruption change, not a cleanup.
- The flip usually hides in implementation rewrites: replacing per-field assignment with whole-model updates (`obj.update(**body)`, full saves, upsert calls) changes what happens to omitted fields without anyone deciding it. When rewriting an update handler, test specifically: send a partial body and verify omitted fields behave exactly as before (kept vs. cleared).
- The null-vs-omitted distinction is part of these semantics: if the endpoint treats `"field": null` (clear it) differently from field-absent (keep it), the rewrite must preserve that — many serializer defaults collapse the two.
- If correct verb semantics are wanted, add them additively: introduce a proper PATCH alongside the existing PUT (or vice versa), leaving the shipped endpoint's behavior untouched, or stage the fix in a new API version.
- If the user explicitly asks to fix the semantics in place, spell out the consequence for current callers: which of their requests will start erasing data or failing to clear it.

**Red flags that you're about to violate this:**
- "PUT is supposed to replace the resource — this endpoint implements it wrong."
- "Updating the whole model in one call is cleaner than copying fields one by one."
- "Partial updates are what PATCH is for; PUT callers should send complete objects."
- "The ORM's update method handles all of this more idiomatically."
- "No response shape changed, so this refactor is contract-neutral."

### Version API Changes, Don't Edit v1

When a requested change to an API endpoint is breaking — different response shape, different semantics, removed or changed behavior — NEVER implement it by editing the existing version in place. A version number in the path (`/v1/`) is a stability promise; changing behavior under it betrays exactly the consumers who pinned it.

- Breaking changes go in a new version: `/v2/endpoint` alongside `/v1/endpoint`, or the project's equivalent (header versioning, date-based versions). The old version keeps its exact current behavior, served by code that still exists.
- Check before assuming: if the codebase already has a versioning scheme, use it. If it has none, surface the question to the user — "this change is breaking; should I add it as a new versioned endpoint or change it in place?" — rather than silently choosing in-place.
- Watch shared internals: modifying a service, formatter, or serializer that multiple versions call changes ALL versions. Implementing v2 must not reach through shared code into v1's behavior — fork or parameterize the shared path so v1's output is bit-for-bit unchanged.
- "Copy, then modify the copy" is correct engineering at a version boundary, even though it feels like duplication. The duplication is the feature: it's what lets v1 stand still.
- Version inflation is also real: do not spin up a new version for changes that are purely additive (new optional fields, new endpoints). Versions are for breaks.

**Red flags that you're about to violate this:**
- "Creating a whole new version for one endpoint change is overkill."
- "The user asked for the new behavior — they didn't mention keeping the old one."
- "I'll just update the shared formatter; both versions get the improvement."
- "v1 is old anyway; surely everyone is meant to be on the new behavior."
- "Duplicating this handler violates DRY."
