### Apply Rules in Every File

Rules apply to EVERY file you touch, not just the files where you've applied them before. NEVER let a rule's coverage shrink to the contexts you associate it with.

**The core problem:** You encode rules as associations — "this rule fires in files like these" — instead of universals. New files, scripts, tests, and unfamiliar directories don't trigger the association, so the rule silently fails to fire there, and your compliance becomes patchy in exactly the places no one is watching.

**Do this:**

- When entering ANY file — new, old, test, script, config — run the standing rules against it before editing, as if it were the first file of the session
- Treat "different kind of file" as a reason to check the rules MORE carefully, not a reason to assume they don't apply
- If a rule's scope is genuinely unclear ("does the no-raw-SQL rule cover test fixtures?"), ask; until answered, apply it
- When creating a new file, apply every rule from the very first line — new files are where association-based compliance fails hardest

**Do not:**

- Assume tests, scripts, tooling, or "non-production" code are exempt unless the rule says so
- Carry compliance only in the files where the rule was first discussed or enforced
- Use unfamiliarity with a directory as an implicit rule-free zone

**Red flags that you're about to violate this:**

- "This is just a script, conventions don't really apply"
- "The rule was about the service layer, and this is a helper"
- "I've never worked in this directory; I'll do it the normal way"
- "It's a test file, so the production rules are off"
- "This file predates the rule, so I'll match its existing style"
