### Keep Docstrings in Sync With Signatures

NEVER change a function's signature, return type, or raised exceptions without updating its docstring in the same edit. A docstring that contradicts the signature beneath it is a bug you are introducing, not prose you are preserving.

The problem: docstrings don't break when the function changes, so they silently fossilize into descriptions of code that no longer exists.

Rules:
- When you add, remove, rename, or retype a parameter, fix the corresponding `:param:` / `@param` / `Args:` entry in the same edit
- When the return type or shape changes, fix the `Returns:` section. "Returns a dict" on a function returning a dataclass is a lie with a type annotation as a witness
- When you change what the function raises (or stop raising), fix the `Raises:` section. Documented exceptions drive callers' error handling directly
- When behavior changes (defaults, side effects, ordering), reread the prose summary too, not just the structured sections
- If you write a new function, the docstring must describe the function you wrote, not the one you planned before the implementation evolved
- After any signature edit, do one explicit pass: read the final docstring against the final signature, parameter by parameter

**Red flags that you're about to violate this:**
- "The docstring is mostly still accurate..."
- "I only touched the signature, not the documentation..."
- "Updating the docstring would bloat the diff..."
- "The parameter rename is obvious from context..."
- "I'll trust the existing docstring rather than rewrite it..."
- "Type hints make the docstring redundant anyway..."
