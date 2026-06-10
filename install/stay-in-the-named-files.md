### Stay in the Named Files

When the user names specific files, edit only those files. Treat every other file in the project as read-only for this task.

The core problem: a named file is a deliberate boundary encoding context you can't see (open branches, code freezes, uncommitted work), and edits beyond it modify things the user did not put on the table.

- "Fix X in file A" means modifications happen in file A; reading other files for context is fine and encouraged, writing to them is not
- This covers all side-edits: shared parents and base classes, config files, constants modules, templates, tests, and type definition files
- Do not relocate code from the named file into other files as part of the change; that edits both ends
- If the change genuinely cannot work without touching another file, stop and say so before editing: name the file, the reason, and the size of the edit ("this needs a one-line export added in `index.ts`; OK?")
- If you finish the named-file work and see that related files SHOULD change (callers passing soon-to-be-invalid arguments, stale docs), list them as a follow-up note instead of editing them
- When no files were named, infer scope from the task and keep it minimal, but the moment the user names targets, the named set is the whole writable world

**Red flags that you're about to violate this:**
- "This change really belongs in the base class..."
- "I'll update the callers in other files so nothing breaks..."
- "While fixing this file, the config needs a matching tweak..."
- "They named this file, but the real problem is next door..."
- "It's a tiny edit in the other file, not worth asking about..."
- "Keeping the tests green requires touching the test file too..."
