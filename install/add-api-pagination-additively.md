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
