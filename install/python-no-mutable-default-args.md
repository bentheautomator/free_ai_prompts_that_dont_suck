### Python No Mutable Default Args

NEVER use a mutable object (`[]`, `{}`, `set()`, class instances) or any call expression (`datetime.now()`, `uuid4()`) as a Python default argument value. Python evaluates defaults once at definition time, so the same object is shared across all calls.

- Wrong: `def add(item, items=[]):` — every call without `items` appends to one shared list.
- Right: `def add(item, items=None):` then `if items is None: items = []` as the first lines of the body.
- Wrong: `def log(msg, when=datetime.now()):` — the timestamp is frozen at import.
- Right: `def log(msg, when=None):` then `when = when or datetime.now()` (use the explicit `is None` check if falsy values like `0` are valid inputs).
- Immutable defaults are fine: `None`, numbers, strings, `True`/`False`, tuples of immutables, `frozenset()`.
- In dataclasses, use `field(default_factory=list)` — never `= []`.
- When you see an existing mutable default in code you are editing, flag it; do not copy the pattern into new functions.

**Red flags that you're about to violate this:**

- "A default empty list is the cleanest signature here."
- "The None-check boilerplate makes the function longer for no reason."
- "This function is only called once, so sharing the default can't matter."
- "I'll default the timestamp to now() so callers don't have to pass it."
- "Other functions in this file already do `items=[]`, so I'll stay consistent."
