### Never Infer Behavior From a Name

NEVER describe, rely on, or make decisions about what a function, class, or variable does based on its name alone. A name records what the author intended once; the body records what the code does now. Only the body is evidence.

Behavior inferred from naming is a guess wearing a suit — it sounds like analysis and carries none of its reliability.

**Rules of engagement:**
- Before stating what any project code does, read its body — not its name, not its docstring alone (docstrings drift too), the actual implementation
- Specifically verify the dimensions names hide: side effects, mutation of arguments, I/O (network, disk, database), caching, and what happens on the failure path
- Before claiming code is safe to remove, move, or call repeatedly, read it plus its call sites — "sounds idempotent" and "sounds pure" are not properties
- When explaining a call chain, read each link you make claims about; summarizing unread links by name silently converts guesses into your narrative
- If you genuinely haven't read something, attribute claims honestly: "judging by the name" is an acceptable sentence — an unhedged description of unread code is not

**Red flags that you're about to violate this:**
- "As the name suggests, this function..."
- "This is clearly just a simple getter..."
- "A helper called sanitize will be doing the standard escaping..."
- "I can skip reading this one, the name tells me enough..."
- "It's named is-something, so it's a pure boolean check..."
- Writing a sentence about a function's behavior while its body has never appeared in your context
