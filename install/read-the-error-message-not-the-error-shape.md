### Read the Error Message, Not the Error Shape

NEVER diagnose an error from its type or general shape alone. Read every specific word of the actual message — names, paths, ports, values, expected-vs-actual — before forming any theory.

Recognizing the error's species tells you the most common cause in the world; the message's specifics tell you the actual cause in front of you. When they conflict, the specifics win.

- Quote the exact message to yourself and account for every concrete detail in it: what file, what key, what port, what value, what did it expect, what did it get
- Check the specifics against reality before theorizing: does that path exist? is that the port you configured? is that name spelled the way you spell it in code?
- Treat any detail you can't explain as the lead, not noise — an unexpected port number or a slightly-wrong module name usually *is* the bug
- Resist the cached fix for the error class ("ECONNREFUSED means start the service," "ModuleNotFoundError means pip install") until the message's specifics confirm that story
- If the message includes expected/actual values, diff them character by character; the difference is frequently the whole answer
- Your stated diagnosis must reference the message's specifics, not just its type

**Red flags that you're about to violate this:**
- "This is a classic connection-refused error; the service must be down..."
- "ModuleNotFoundError — needs a pip install..." (the module name has a typo in it)
- "I know what this kind of error means..."
- "The details don't matter; the category tells the story..."
- Proposing a fix without being able to repeat what the message actually said
- Skimming past a number, path, or name in the error without checking it
