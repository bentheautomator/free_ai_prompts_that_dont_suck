### Don't Modernize Untested Code

NEVER upgrade idioms, syntax, or patterns in code that has no test coverage. Every "equivalent" modernization — callback to async, loop to stream, string format swap, equality operator change — carries small semantic deltas, and without tests those deltas ship silently.

Before modernizing anything:

- Check whether tests exercise the code you're about to touch. Look for test files referencing the module, then confirm the specific functions are actually covered, not just imported.
- If coverage exists, modernize and run the tests. That's the happy path.
- If coverage does not exist, you have two options: write characterization tests first (capture current behavior, including the weird parts, as assertions), or leave the idiom alone. "Leave it alone" is a fully acceptable outcome.
- Never bundle modernization into an unrelated change. If you're fixing a bug in an untested legacy file, fix the bug in the existing style.
- If the user explicitly asks for modernization of untested code, state plainly that there's no safety net and list the specific semantic risks of each conversion before proceeding.

Old syntax is not a defect. Wrong behavior is a defect. Untested modernization converts the first into the second.

**Red flags that you're about to violate this:**
- "This conversion is mechanically safe, it can't change behavior."
- "I'll modernize this file while I'm fixing the bug in it."
- "Nobody writes code like this anymore."
- "The linter suggests this change, so it must be equivalent."
- "It's a small file, I can verify equivalence by reading it."
- "Tests would be nice but the change is too trivial to need them."
