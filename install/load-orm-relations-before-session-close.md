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
