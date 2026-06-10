---
title: Batch Per-Item Network Calls
slug: batch-per-item-network-calls
category: performance
tags: [universal, performance, network]
works_with: all
severity: high
one_liner: "Stops loops that make one API or RPC call per item instead of one batch call"
---

# Batch Per-Item Network Calls

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from issuing one HTTP/RPC call per element of a collection when the API offers a batch, bulk, or multi-get form.

**[Copy-paste ready version](../../install/batch-per-item-network-calls.md)** — just the instruction block, no explanation.

## The Problem

This is the N+1 query's network-shaped sibling, and it's more expensive per offense. `for user in users: stripe_customer = api.get_customer(user.stripe_id)`. A loop calling `s3.head_object` per key. A sync job PUTting records to a partner API one at a time, 80ms round trip each. At 5,000 items that's 6 minutes 40 seconds of pure latency for what a single bulk endpoint would do in two seconds — plus 5,000 chances to hit a rate limit, 5,000 TLS handshakes' worth of overhead, and 5,000 independent failure points midway through which your job is half-done with no record of which half.

AI assistants write the per-item version because the singular endpoint is the one documented first, the loop is the universal idiom for "do this for each," and nothing about `get_customer(id)` advertises that `get_customers(ids=[...])`, a `/batch` route, or a multi-get exists. The per-item loop also works perfectly in development against 5 items.

Every serious API has a batch form precisely because providers got tired of this: bulk endpoints, `mget`, pipeline modes, `IN`-style filter parameters, async job-submission APIs. The assistant has to be told to go look for them.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It inserts a search step before the loop.** The AI defaults to the first API shape it knows; "check for the plural" makes discovering the batch form part of the task instead of a lucky accident.
2. **It prices the loop in round trips and tokens.** Latency-times-N plus rate-limit-burn is arithmetic the AI can do at write time, making the per-item version visibly expensive before it runs.
3. **It closes the parallelization escape hatch.** Naming "just parallelize the singles" as a red flag matters, because that's the AI's favorite fix and it converts a slow job into a 429 storm.
4. **It verifies at the wire.** Request count per run is observable and fixture-size-proof; ceil(N / batch_size) is a pass/fail number.

## Origin

A nightly inventory sync pushed price updates to a marketplace API one PUT at a time. At 2,000 SKUs it took four minutes. The catalog grew to 90,000 SKUs and the job took five hours, except it never finished: around item 60,000 it would trip the provider's daily rate limit and die, leaving a third of the catalog with day-old prices, which is how the team found out via underpriced orders. The provider had offered a bulk-update endpoint (up to 500 items per call) the entire time. The rewrite finished in under three minutes and used 180 requests instead of 90,000.
