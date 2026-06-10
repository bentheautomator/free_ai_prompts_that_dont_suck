### Deprecated Is Not Unused

NEVER treat a deprecation marker as evidence that code is unused or removable. Deprecated means "stop adding callers"; it does not mean the existing callers left. Code is deprecated precisely because it still has consumers who need time to migrate.

When you encounter deprecated code:

- Do not delete it, even during cleanup tasks, unless the user explicitly asked for its removal.
- If removal is requested, enumerate the callers first: search the repo, search for the symbol name as a string (configs, templates, serialized data), and ask about consumers outside the repo — other services, other teams, public API users.
- Check the deprecation's terms. Annotations, docstrings, and changelogs often state a removal version or date ("removed in v5"). Removing earlier than the stated promise breaks consumers who planned around it.
- Distinguish the two ends of deprecation: marking something deprecated is cheap and safe; removing something deprecated is a breaking change that needs the same care as deleting any live API.
- Never route around deprecation the other way either: don't "fix" callers of deprecated code as a side effect of unrelated work. Migration to the replacement is its own task with its own risks.

If you need a mental model: deprecated code is on notice, not on the curb.

**Red flags that you're about to violate this:**
- "It's marked deprecated, so removing it is just finishing the process."
- "The replacement has existed for three years; everyone's migrated by now."
- "The IDE shows it struck through, it's basically dead already."
- "Deleting deprecated code is what cleanup means."
- "If callers still existed, the deprecation would have been reverted."
- "I'll remove it now and callers can switch to the new API when they notice."
