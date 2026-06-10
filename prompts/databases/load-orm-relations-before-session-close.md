---
title: Load ORM Relations Before the Session Closes
slug: load-orm-relations-before-session-close
category: databases
tags: [universal, databases, orm]
works_with: all
severity: medium
one_liner: "Lazy-loading relations after the session is gone, then 'fixing' it badly"
---

# Load ORM Relations Before the Session Closes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents detached-object lazy-load crashes and the worse fixes AI assistants reach for to silence them.

**[Copy-paste ready version](../../install/load-orm-relations-before-session-close.md)** — just the instruction block, no explanation.

## The Problem

The function fetches an order inside a session, returns it, and the caller touches `order.items`, after the session closed. SQLAlchemy raises `DetachedInstanceError`; Hibernate throws `LazyInitializationException`; Django quietly issues a brand-new query from wherever the access happened, including the template layer. The AI wrote it this way because lazy loading is invisible in code review: `order.items` looks like attribute access, not like a database query with a lifetime requirement on the session that produced the object.

The error itself is the cheap part. The expensive part is what the AI does to make it go away. Popular bad fixes, each of which it will produce confidently: keep the session open longer (often forever, leaking connections and creating long-transaction problems); set `expire_on_commit=False` and serve stale objects; switch the ORM to eager-load *everything* globally, turning every single-row fetch into a five-table join; enable "open session in view" so the web layer can lazily query at render time, scattering hidden queries through templates; or re-fetch the object from a second session inside the accessor, doubling queries everywhere. All of these silence the symptom by blurring the data-access boundary further.

The honest fix runs the other direction: decide what data the caller needs, load exactly that *inside* the session, and hand back something complete.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Load ORM Relations Before the Session Closes

ALWAYS load every relation the caller will need before the session/transaction that fetched the object ends. An ORM object's lazy attributes are deferred queries with a lifetime requirement; accessing them after the session closes either crashes (`DetachedInstanceError`, `LazyInitializationException`) or fires hidden queries from presentation code.

- At the data-access boundary, load deliberately: `selectinload`/`joinedload` (SQLAlchemy), `select_related`/`prefetch_related` (Django), `includes` (Active Record), fetch joins (JPA), for exactly the relations the caller uses. Name them; don't guess "all."
- Functions that return ORM objects across a session boundary must document or guarantee what's loaded. Better: return plain data (DTO, dict, dataclass) built inside the session, so the boundary is explicit and nothing lazy escapes.
- Banned fixes for a detached/lazy-load error, propose none of these without flagging the trade-off:
  - Extending session lifetime to wherever the access happens ("open session in view," module-level sessions).
  - Global eager loading of all relations on the model.
  - `expire_on_commit=False` purely to silence the error.
  - Re-querying inside property accessors.
- When you hit a lazy-load error, treat it as a boundary-design message: "this caller needs `items` and `customer`; load them at fetch time." Fix the fetch, not the session scope.
- In templates/serializers, attribute access that triggers queries is a hidden dependency; serialize from data prepared in the handler instead.

**Red flags that you're about to violate this:**

- "I'll just keep the session open until the request finishes..."
- "Setting expire_on_commit=False makes the error disappear..."
- "Eager-load everything so this can never happen again..."
- "The template can fetch what it needs when it renders..."
- "Accessing the attribute again re-queries automatically, problem solved..."

---

## Why It Works

1. **It reveals the disguise.** `order.items` reads as attribute access; restating it as "a deferred query with a session-lifetime requirement" gives the AI the model it needs to see the bug at write time instead of at crash time.

2. **It blocklists the symptomatic fixes by name.** Every popular bad fix genuinely makes the error stop, which is why the AI reaches for them; naming them as banned forces the boundary-level fix to be considered first.

3. **It promotes the structural alternative.** Returning plain data from the session makes lazy escape impossible by construction, an option the AI rarely generates because the ORM object is already in hand.

4. **It treats the exception as design feedback.** "The caller needs X and Y at fetch time" converts an annoying crash into a precise specification, which is the reading that produces good code.

## Origin

A background worker started crashing with detached-instance errors after a refactor moved serialization outside the session block. The assistant's fix was `expire_on_commit=False` plus a session held open for the worker's whole lifetime, which stopped the crashes and quietly began serving objects whose data was hours stale, while the long-lived connection pinned a transaction that blocked a midnight vacuum. The eventual fix was four lines: `selectinload` the two relations the serializer used, and close the session where it always should have closed.
