### No Drive-By Docstring Pass

Do not add docstrings or comments to code you are not otherwise changing. Document what you create; leave what you merely visited alone.

The core problem: docstrings generated for unfamiliar code are inferences presented as fact, and narrating comments are drift liabilities, so a documentation pass nobody asked for adds confident noise rather than knowledge.

- New functions, classes, or modules you write may carry documentation appropriate to the project's existing style and density
- Do not add docstrings to existing undocumented functions while passing through their file
- Do not add inline comments that restate code ("# loop over users" above a loop over users), in your code or anyone's
- Do not rewrite, "improve," or reformat existing comments and docstrings in code you aren't changing
- If you changed a function's behavior and its existing docstring is now wrong, updating that docstring is in scope and required; that is maintenance, not creep
- If you notice documentation that is absent where it's badly needed, or wrong in a way you can prove, mention it in one sentence instead of fixing it unasked

**Red flags that you're about to violate this:**
- "While I'm in this file, I'll document the other functions..."
- "Docstrings everywhere will help future maintainers..."
- "I'll add comments to make this section clearer..."
- "This codebase has poor documentation coverage, I can improve it..."
- "A quick docstring pass makes the diff more professional..."
