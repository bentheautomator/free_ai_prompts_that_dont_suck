---
title: Keep Business Logic Out of HTTP Handlers
slug: keep-business-logic-out-of-http-handlers
category: architecture
tags: [universal, architecture, layering]
works_with: all
severity: high
one_liner: "Pricing rules and state machines accreting inside route handlers"
---

# Keep Business Logic Out of HTTP Handlers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing business rules directly inside route handlers, where they're welded to the web framework and invisible to every other entry point.

**[Copy-paste ready version](../../install/keep-business-logic-out-of-http-handlers.md)** — just the instruction block, no explanation.

## The Problem

Ask for "an endpoint that applies a discount" and the AI writes the discount calculation inside the route handler, between `request.json()` and `jsonify()`. The rule works. Then the team adds a CLI import job, a background worker, and a GraphQL API — and the discount logic exists in exactly one place none of them can call without faking an HTTP request. So it gets copy-pasted, and now there are four discount rules that agree until the first time someone updates three of them.

The AI does this because the task arrived framed as an endpoint. The handler is the file that's open, the request data is right there, and inlining the logic produces the shortest diff that passes the test. Whether the logic belongs to the transport layer or the domain is a question nothing in the prompt forces it to ask.

Handlers welded to business rules are also untestable without the framework: every test of "is the discount correct" becomes a test of routing, serialization, and middleware. The 2-line rule needs a 40-line test harness.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Business Logic Out of HTTP Handlers

NEVER put business rules, calculations, or state transitions inside an HTTP handler, controller, or route function. Handlers translate between the wire and the domain — they do not decide anything.

Logic written in a handler is callable only via HTTP, testable only through the framework, and destined to be copy-pasted into the next entry point that needs it.

- A handler may: parse/validate the request shape, call ONE domain function or service method, and translate the result (including domain errors) into a response. That's the whole job
- Put the actual rule in a domain/service function that takes plain values or domain objects — never the request — and returns a result the handler converts to a status code
- If the handler is growing branches (`if user.plan == "pro" and order.total > ...`), that conditional is domain logic; move it before it grows a sibling
- Database queries that embody business decisions (which records qualify, in what order, with what cutoff) belong behind the domain function too, not inline in the route
- The test for "is the rule correct" must be writable without an HTTP client or test server; if it isn't, the logic is in the wrong place

**Red flags that you're about to violate this:**
- "It's only a few lines of logic, a separate function is ceremony..."
- "The request data is already parsed right here, why pass it along..."
- "This rule is only ever needed by this endpoint..."
- "I'll extract it later if another caller shows up..."
- "The framework docs put logic in the handler in their examples..."

---

## Why It Works

1. **It gives the handler a checkable job description.** "Parse, call one function, translate the result" is a shape the AI can match against its output; "keep handlers thin" is not.

2. **It uses testability as a tripwire.** "Can I test the rule without a test server?" is a mechanical question that detects misplaced logic even when the code looks tidy.

3. **It catches the rule at three lines, not three hundred.** Naming the growing-conditional moment matters because handlers cross the threshold gradually — there is never a single diff where the logic obviously moved in.

4. **It pre-empts the second entry point.** The cost of handler-bound logic arrives when a non-HTTP caller appears; the rule makes the AI pay the (tiny) extraction cost now, when it's one function instead of one migration.

## Origin

A subscription-renewal rule lived inside a POST handler for two years. When the team added a nightly auto-renewal worker, the assistant writing it couldn't call the handler, so it reimplemented the rule — minus a proration edge case nobody remembered. The two implementations drifted for five months until a customer was charged twice in one cycle, and the postmortem's first action item was extracting the rule into a service function: a 30-minute change that had been available the whole time.
