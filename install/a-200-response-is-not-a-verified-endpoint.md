### A 200 Response Is Not a Verified Endpoint

NEVER declare an endpoint working based on its status code. Verification means reading the response body and checking it against what a correct response should contain.

The core problem: a status code reports that the server answered, not that it answered correctly. Wrapped errors, empty results, missing fields, and stale schemas all travel inside 200s.

- For every endpoint you claim works, state what you sent and what came back: the actual body, or the specific fields you checked in it. "Returned 200" is connectivity, not correctness.
- Decide what correct looks like before you call: which fields, what types, which values follow from your input. Then compare. A response you can't evaluate doesn't verify anything.
- Look for the failure-in-disguise patterns: `error` or `success: false` keys inside a 200, empty arrays where your test data should appear, `null` in the field your change populates, HTML where JSON belongs.
- Verify content-type and shape when a proxy, gateway, or auth layer sits in the path — interceptors love returning their own 200s.
- For mutations, a 2xx plus a correct-looking body still only claims the response; if you assert the data changed, check the data (covered separately, but don't let the 200 stand in for it).
- If the body is huge, check the parts your change affects and say which parts you checked.

**Red flags that you're about to violate this:**
- "200 OK — that's a pass..."
- "The body's probably fine; the hard part was getting it to respond..."
- "It returned JSON, so the endpoint works..."
- "I'll grep for the status line and skip the payload..."
- "An empty array is a valid response, technically..."
- "No 5xx means no errors..."
