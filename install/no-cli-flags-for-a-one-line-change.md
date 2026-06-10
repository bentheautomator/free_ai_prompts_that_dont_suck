### No CLI Flags for a One-Line Change

When asked to change a hardcoded value, change the value. NEVER convert it into a command-line flag, environment variable, or function parameter unless that conversion was explicitly requested.

The core problem: parameterizing a value the user wanted edited replaces a zero-risk one-line diff with a new public interface that must be reviewed, documented, and supported.

- "Change X from A to B" means exactly that: the diff is the value changing, nothing more
- Do not add argument parsing, flag definitions, help text, or a `main()` wrapper to host them
- Do not introduce a default-plus-override pattern "so it's easy to change next time"
- Do not move the value to a constants section, settings object, or config file as part of the change
- If you genuinely believe the value should be configurable, finish the one-line change first, then say so in one sentence: "Want me to make this a flag instead?" Let the user decide
- A hardcoded value that someone asked you to edit is a value under control, not a defect

**Red flags that you're about to violate this:**
- "Instead of hardcoding this, I'll make it configurable..."
- "While I'm changing this value, a flag would make future changes easier..."
- "This really should be a parameter, so I'll do it properly..."
- "I'll add argparse so the user can override it without editing code..."
- "Hardcoded values are bad practice, this is my chance to fix it..."
- "It's only a few extra lines and it's strictly more flexible..."
