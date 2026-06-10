---
title: A 200 Response Is Not a Verified Endpoint
slug: a-200-response-is-not-a-verified-endpoint
category: verification
tags: [universal, verification, api]
works_with: all
severity: high
one_liner: "Declaring an endpoint working from its status code without reading the body"
---

# A 200 Response Is Not a Verified Endpoint

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from calling an endpoint verified because it returned 200, without ever reading what it returned.

**[Copy-paste ready version](../../install/a-200-response-is-not-a-verified-endpoint.md)** — just the instruction block, no explanation.

## The Problem

`curl` the endpoint, see `200 OK`, report "endpoint working." But a 200 carrying `{"error": "internal failure"}` is a thing that real frameworks really return — wrapped errors, empty arrays where data should be, `null` for the field that matters, an HTML login page from a proxy, or yesterday's schema with the new field silently absent. The status code says the server formed a response; it says nothing about whether the response is right.

Assistants stop at the status line because it's the first thing in the output and it matches the question they were implicitly asking: "did it blow up?" Reading the body means knowing what the correct body should look like and comparing — actual work with the possibility of a wrong answer. The status check is binary, instant, and almost always green, which makes it the perfect verification for someone who wants to be done.

So "API verified" ships, the frontend integrates against it, and the bug report comes from whoever first looked inside the envelope: the field is missing, the list is empty, the error is wearing a success code. The verification happened; it just verified the transport layer.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It splits "answered" from "answered correctly."** The status code legitimately proves the first; the model conflates the two because they usually coincide. Naming the split makes status-only checks feel as partial as they are.

2. **It requires a defined expectation before the call.** Deciding what correct looks like first prevents the post-hoc move where whatever came back gets rationalized as acceptable.

3. **It catalogs the disguised failures.** Errors-in-200s, empty arrays, nulls, proxy HTML — a concrete rogues' gallery converts "read the body" from advice into a scan with known targets.

4. **It binds the claim to quoted evidence.** "Sent X, got body Y, field Z correct" cannot be generated honestly without doing the check; "endpoint working" can.

## Origin

An assistant wired up a new reporting endpoint, curled it, saw 200, and reported it verified. The frontend team built a whole dashboard against it before anyone noticed every response was `{"data": [], "warnings": ["query failed, returning empty result"]}` — the handler caught its own SQL error and returned a friendly empty success. The endpoint had never produced a row. The status code had been telling the truth the whole time; it just wasn't answering the question anyone thought it was.
