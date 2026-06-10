---
title: Don't Document Internal APIs as Public
slug: dont-document-internal-apis-as-public
category: documentation
tags: [universal, docs]
works_with: all
severity: medium
one_liner: "Docs presenting private helpers and internal endpoints as supported API surface"
---

# Don't Document Internal APIs as Public

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing documentation that presents internal helpers, private endpoints, and implementation details as if they were supported public API.

**[Copy-paste ready version](../../install/dont-document-internal-apis-as-public.md)** — just the instruction block, no explanation.

## The Problem

Asked to "document the API," the AI documents *everything*: the public `client.query()` method, sure, but also `_build_connection_pool()`, the `/internal/flush-cache` endpoint, and the `__experimental_batch` option that exists behind a feature flag for one design partner. Each gets the same confident reference-page treatment: parameters, examples, return values. The docs now advertise a surface three times larger than the one the maintainers intend to support.

Documentation is a promise. The moment an internal function appears in the docs with a usage example, someone will use it, and Hyrum's Law does the rest: the next refactor of that "internal" helper is now a breaking change with angry users, even though the underscore prefix said everything the team thought it needed to say. The AI manufactured a compatibility contract nobody agreed to.

Models do this because they document what they can see, and they can see all of it. Visibility conventions — underscore prefixes, `internal/` packages, `@private` tags, missing exports — are signals about *intent*, and intent doesn't survive the flattening into "here are the functions, document them."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Document Internal APIs as Public

NEVER document internal APIs, private helpers, or unexported symbols in user-facing documentation. Documenting something is publishing a support contract for it.

The problem: docs are read as promises. An internal function with a reference page and a usage example will acquire external callers, and then it can never be safely changed again.

Rules:
- Respect the project's visibility signals: underscore prefixes, `internal/` or `private/` paths, missing exports, `@internal`/`@private` annotations, symbols absent from `__all__` or the public index. None of these belong in user docs
- "Document the API" means the public API. If the boundary is ambiguous, ask or state your assumption: "I documented exported symbols only"
- Endpoints under `/internal/`, admin routes, and debug interfaces don't go in API references, even though they technically respond to requests
- If users genuinely need something that's currently internal, that's a finding to raise ("`_retry_policy` seems needed for X but is private"), not a license to document it as available
- Internal docs are fine in internal places: contributor guides and architecture docs can and should describe internals, clearly framed as implementation that may change
- When documenting a public function, don't leak internals through it: examples shouldn't reach into private modules to set up state

**Red flags that you're about to violate this:**
- "More complete documentation is better documentation..."
- "It's in the codebase, so it's fair game..."
- "Users might find this internal function useful..."
- "The underscore is just a convention..."
- "I'll document it with a note saying it's internal..." (in user docs, the note evaporates; the example gets copied)
- "The endpoint works if you call it, so it's part of the API..."

---

## Why It Works

1. **It states the docs-as-contract mechanism.** The model treats documenting as describing; users treat it as promising. Naming that gap explains *why* completeness is the wrong objective for user docs.

2. **It maps intent signals to a checkable list.** Underscores, internal paths, export lists, and annotations are greppable. The rule converts "respect intent" into pattern checks the model performs reliably.

3. **It provides the pressure valve.** The urge to document useful internals gets a legitimate outlet — raise it as an API gap — so following the rule doesn't mean swallowing the observation.

4. **It separates audience, not content.** Internals deserve documentation, for contributors. Routing by audience preserves the writing while preventing the false promise.

## Origin

A data library's AI-expanded documentation gained reference pages for several underscore-prefixed helpers, complete with examples. Within two release cycles, a scraper found external projects importing `_chunked_read` directly, copied verbatim from the docs. When the maintainers restructured the IO layer, the "internal" change broke enough downstream users that they shipped a compatibility shim and kept it for over a year, supporting a function they had never once intended anyone to call.
