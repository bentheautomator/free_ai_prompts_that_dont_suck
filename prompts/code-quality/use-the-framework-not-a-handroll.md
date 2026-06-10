---
title: Use the Framework, Not a Handroll
slug: use-the-framework-not-a-handroll
category: code-quality
tags: [universal, duplication, frameworks]
works_with: all
severity: high
one_liner: "AI hand-rolling logic the project's framework or libraries already provide"
---

# Use the Framework, Not a Handroll

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from reimplementing, badly, what the project's framework and installed libraries already do.

**[Copy-paste ready version](../../install/use-the-framework-not-a-handroll.md)** — just the instruction block, no explanation.

## The Problem

A Django project asks for pagination and gets a hand-written `OFFSET`/`LIMIT` query with manual page math — in a framework that ships `Paginator`. An Express app needs request parsing and receives a homemade body-buffering function instead of the `express.json()` middleware already mounted two lines up. A React codebase gains a bespoke `useFetch` with a raw `useEffect`, a loading flag, and a race condition, while the project's `react-query` dependency sits installed and idle.

AI assistants hand-roll because generating the primitive version is a self-contained task that needs no knowledge of the project, while using the framework's facility requires knowing it exists and that it's available here. Generation always wins that race unless something interrupts it. The cost is not just redundancy: the handroll is almost always the *worse* implementation — missing the edge cases (unicode, time zones, request cancellation, SQL injection guards) that the framework spent a decade accumulating. You get more code, owned by you, doing less, with bugs the ecosystem already fixed years ago.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use the Framework, Not a Handroll

NEVER hand-implement functionality that the project's framework or installed dependencies already provide. Before writing infrastructure-flavored code — pagination, validation, serialization, auth checks, caching, retries, date math, query building, escaping, parsing — check whether the stack already does it.

Your hand-rolled version will be longer, less correct, and permanently owned by this team. The framework's version has had its edge cases beaten out of it by years of other people's incidents.

**Before writing such code:**
- Check what the framework offers: ORMs paginate, validate, and escape; web frameworks parse, route, and handle CORS; standard libraries do more than you assume
- Check the installed dependencies (`package.json`, lockfiles, `requirements.txt`, `go.mod`) — a project with `zod` installed wants schemas, not if-chains; a project with `date-fns` wants `addDays`, not millisecond arithmetic
- Check how the codebase already solves it: if existing endpoints use the framework's paginator, your endpoint does too
- Treat hand-rolling as the option of last resort, taken only when the stack genuinely lacks the facility — and say so when you do, so the choice is visible
- Security-adjacent handrolls (escaping, sanitization, crypto, query construction) are forbidden outright when any library alternative exists

**Red flags that you're about to violate this:**
- "This is simple enough to implement directly..."
- "I'll write a small utility rather than pull in machinery..."
- "A custom version gives us more control..."
- "I don't see them using the framework's feature, so I'll roll my own..." (did you look?)
- "It's just date math / just escaping / just a regex..."
- Writing infrastructure code without having checked the dependency manifest this session

---

## Why It Works

1. **It interrupts generation with a lookup.** The handroll happens because generating is frictionless. Requiring a stack check first inserts the one step that lets the framework's facility win the race.

2. **It reframes the handroll as a liability, not a solution.** "More control" and "simpler" are how the model frames ownership of fresh bugs. Naming the maintenance and edge-case costs flips the valence of the choice.

3. **It draws a hard line at security primitives.** Most of the rule is judgment; escaping and crypto are not. An absolute ban where the downside is a CVE removes discretion exactly where discretion is most dangerous.

4. **It makes the last resort auditable.** Allowing handrolls "when the stack lacks the facility, said out loud" preserves legitimate cases while ensuring a human can veto the assessment.

## Origin

A reporting feature needed CSV export from a Python service. The AI wrote its own CSV serializer — string joins with commas, a manual quote-wrapper for fields containing commas. The standard library's `csv` module was, naturally, right there. The handroll mishandled embedded quotes and newlines, which no test data contained but plenty of customer data did. Finance imported a quarter's worth of subtly corrupted exports before a mismatched row count exposed it, and the cleanup involved re-running every export and a very uncomfortable email.
