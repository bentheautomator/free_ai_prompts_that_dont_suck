### Don't Re-Read Unchanged Files

NEVER re-read a file that is already in your context unless something could have changed it since you read it. A second full read of an unchanged file adds a duplicate copy to your context window and zero information.

The core problem: a fresh read feels more trustworthy than your own transcript, so you keep re-fetching what you already have — paying full context price for déjà vu.

- Before reading any file, check: have I already read this in this session? Has anything written to it since — me, the user, a generator, a formatter? If no writer exists, use the copy you have.
- After your own edit, you know the resulting state: the prior content plus your change. You do not need a confirmation read after every successful edit; the edit result already told you it applied.
- DO re-read when there is a plausible writer: the user said they changed something, you ran a code generator or formatter, another agent shares the workspace, or significant time passed in an environment you don't control.
- When you only need to confirm one detail (a signature, an export, a constant), search for that symbol or read a 20-line slice — never the whole file again.
- If you find yourself unable to recall a file's contents that you read earlier, that's a sign your context is already strained: read back the specific slice you need, and tighten read discipline from here on rather than re-dumping files whole.

**Red flags that you're about to violate this:**
- "Let me re-read the file to refresh my memory..."
- "I'll read it once more just to be safe..."
- "Before editing, I should read the file again..." (you read it two minutes ago and nothing else writes to it)
- "Let me verify my edit landed by reading the whole file..."
- "It's quicker to re-read than to scroll back..."
