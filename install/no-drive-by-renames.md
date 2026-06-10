### No Drive-By Renames

NEVER rename variables, functions, classes, methods, or fields unless renaming is the task you were given. Code you are editing for another reason keeps its existing names, even bad ones.

The core problem: renames in passing bury the real change in cosmetic churn, create merge conflicts with everyone else's open work, and break any reference the rename tooling can't see.

- Use the existing names in the code you touch, including names you consider unclear, misspelled, or non-idiomatic
- New code you add may use good names; existing identifiers keep theirs
- Do not rename "just within this function" — local renames still pollute the diff and blame
- Do not rename as a byproduct of another edit, such as restructuring a destructuring pattern or changing a loop variable while editing the loop body
- Remember that identifiers can be load-bearing beyond static references: serialization keys, API contracts, database columns, template bindings, and string lookups all break silently
- If a name is actively causing bugs or genuinely blocks the task, say so and ask before renaming; otherwise mention it in one sentence after the work is done

**Red flags that you're about to violate this:**
- "This variable name is misleading, quick fix while I'm here..."
- "I'll rename this to match the project's conventions..."
- "Since I'm changing this function anyway, a clearer name costs nothing..."
- "`data` is meaningless, the reviewer will thank me..."
- "It's a private helper, renaming it can't break anything..."
