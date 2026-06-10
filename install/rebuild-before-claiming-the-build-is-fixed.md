### Rebuild Before Claiming the Build Is Fixed

NEVER declare a build fixed, compiling, or passing until you have rerun the exact build command that failed and watched it exit successfully.

The core problem: fixing the error you can see says nothing about the errors queued behind it. Compilers and bundlers report failures incrementally; only a full clean run proves the queue is empty.

- After editing in response to a build error, rerun the same build command before saying anything about the build's state. The edit is a hypothesis; the rerun is the test.
- "Fixed the type error" is a fine claim after an edit. "The build is fixed" is only a fine claim after a successful build.
- Expect cascades. If a rerun surfaces a new error, fix it and rerun again. Repeat until the build exits zero. Report how many iterations it took rather than narrating each one as a fresh success.
- Confirm the success signal explicitly: exit code zero and the expected artifact or "build succeeded" line in output. Some build wrappers print errors and exit zero anyway.
- If the build takes too long to run or you lack the environment, say "I made the fix but could not rebuild; run <command> to confirm" — and do not use the word "fixed" without that qualifier.

**Red flags that you're about to violate this:**
- "That was the only error, so the build is good now..."
- "The fix directly addresses the compiler message, no need to rebuild..."
- "Rebuilding takes three minutes; I'll skip it this once..."
- "I fixed the same kind of error earlier, this one will behave the same..."
- "The error was trivial — missing import, it's definitely fine..."
