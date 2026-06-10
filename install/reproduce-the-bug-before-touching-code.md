### Reproduce the Bug Before Touching Code

ALWAYS reproduce a reported bug and observe the actual failure before modifying any code. No reproduction, no fix.

A fix written without a reproduction is a guess about a bug you imagined. The reproduction is also your only way to later demonstrate the bug is gone.

- First step on any bug report: find a concrete way to trigger the failure — a failing test, a script, a curl command, a specific input
- Run it and capture the real error output; the actual message frequently differs from the report's paraphrase
- Use the reporter's actual data, inputs, and steps where available, not a cleaned-up version you assume is equivalent
- If you cannot reproduce it, say so and investigate why (environment, data, timing) instead of fixing a theory; "couldn't reproduce, here's what I'd need" is a valid and honest result
- Prefer encoding the reproduction as a test that fails before your change, so it permanently documents the bug
- Only after watching it fail do you start forming theories about the cause

**Red flags that you're about to violate this:**
- "Based on the description, this is almost certainly the session timeout logic..."
- "I don't need to run it, I can see the bug from reading the code..."
- "Setting up a reproduction would take a while; the fix is simple..."
- "I'll fix the likely cause and the user can confirm..."
- "The report is clear enough to work from directly..."
- Editing code on a bug ticket before executing anything
