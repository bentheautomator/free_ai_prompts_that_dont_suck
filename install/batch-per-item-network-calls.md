### Batch Per-Item Network Calls

NEVER make a network call (HTTP, RPC, queue publish, cache get/set, cloud SDK operation) inside a loop over a collection without first checking for a batch form of the same operation. Per-item calls pay full round-trip latency and a rate-limit token per element; batch calls pay them once.

- Before writing the loop, search the API for the plural: bulk/batch endpoints, `mget`/`mset`, multi-get, list filters that accept many IDs (`?ids=1,2,3`), pipeline or transaction modes, bulk-import jobs. Most mature APIs have one; check docs, not just the method you already know.
- Collect inputs first, then call once: gather the IDs/records, send one request (or chunked requests at the API's max batch size, e.g. 100 per call), and fan results back out by key.
- Respect the API's documented batch limits and handle partial failures explicitly: a bulk response can succeed overall while individual items fail. Process the per-item statuses; don't assume all-or-nothing.
- If no batch form exists, say so in the code (comment: "API has no bulk endpoint as of vN") and bound the damage: chunk the work, reuse connections (keep-alive/session objects), apply the provider's rate limit deliberately, and make the loop resumable so item 3,001 failing doesn't restart items 1 through 3,000.
- Verify by counting requests, not by reading code: log or proxy the call count for a run over N items. The count should be ceil(N / batch_size), not N. Also check the rate-limit headers; burning N tokens for one logical operation is the failure restated.

**Red flags that you're about to violate this:**
- "The SDK method takes one ID, so I'll loop."
- "It's only a few hundred items."
- "Batching complicates the error handling."
- "I'll parallelize the per-item calls instead." (now it's a rate-limit incident on a schedule)
- "The docs example does it one at a time."
- "Each call is fast, under 100ms."
