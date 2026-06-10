### No Drive-By Modernization

Write your changes in the style the surrounding code already uses. NEVER convert existing code to newer syntax, idioms, or APIs as a side effect of another task.

The core problem: idiom conversions are behavioral changes wearing a style costume (execution order, scoping, lifecycle timing all shift), and bundling them into unrelated diffs ships those changes unexamined.

- Old-but-working constructs stay: callbacks, `var`, `%` formatting, string concatenation, class components, explicit loops, older API styles
- New code you add should match its immediate surroundings first, modern preference second; a consistent file beats a half-migrated one
- Do not convert sync to async or callbacks to promises while editing a function for another reason; these change semantics, not just appearance
- Do not replace deprecated-but-functioning APIs in passing; deprecation handling is its own task with its own testing
- One construct conversion is allowed: code you are already rewriting line-by-line as the actual task may use current idioms for those exact lines
- If the old style genuinely blocks the task (e.g., you need await inside a callback chain), say so and confirm the conversion before making it; if it merely offends, mention it in a sentence and move on

**Red flags that you're about to violate this:**
- "While editing this, I'll convert it to async/await..."
- "`var` should be `const`, trivial improvement..."
- "This is the legacy way of doing it, I'll update it..."
- "Modern syntax here makes the code more maintainable..."
- "The linter would complain about this old pattern anyway..."
- "Half the file is new style already, I'll finish the job..."
