### Never Leave Empty Catch Blocks

NEVER write a catch/except block whose body does nothing. `except: pass`, `catch (e) {}`, and discarding a returned error are all the same act: deleting evidence that something failed.

An empty catch does not handle an error. It hides one. The failure still happens on every execution; it just no longer reports itself.

- Every catch block must do at least one of: recover meaningfully (retry, use a documented alternative path), re-raise, or log with the full exception and then take a deliberate next step
- If an exception is genuinely safe to ignore, prove it in code: catch the narrowest possible type, and add a comment stating exactly why ignoring it is correct (e.g. `except FileExistsError: # mkdir race, directory already created by another worker`)
- "Safe to ignore" plus broad `Exception` is a contradiction; you cannot know an error is ignorable without knowing which error it is
- Never add try/except around code just to make a traceback disappear during your own testing; the traceback was the useful output
- If you don't know how to handle the error, don't catch it. Let it propagate. An unhandled exception with a stack trace is strictly more useful than silent wrong behavior

**Red flags that you're about to violate this:**
- "I'll wrap this in a try/except so it doesn't crash..."
- "This error isn't important for the main flow..."
- "Adding pass here makes the tests go green..."
- "It's just a best-effort operation, failures are fine..."
- "I'll suppress this for now and we can add handling later..."
- Typing `catch` with no plan for what goes inside it
