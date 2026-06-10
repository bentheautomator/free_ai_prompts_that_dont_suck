### Commit Messages Explain Why, Not What

Write commit messages that record why the change was made. NEVER write a message that merely restates the diff; the diff already stores the what, permanently and precisely.

- Subject line: imperative mood, under 72 characters, naming the change at the level of intent: `fix: prevent session expiry during long uploads`, not `update session.py`.
- Body (for anything non-trivial): explain the motivation — the bug observed, the requirement, the constraint that forced this approach. If you considered an obvious alternative and rejected it, say why in one line.
- Banned message patterns: `update <filename>`, `fix bug`, `changes`, `address feedback`, `WIP`, and any message that lists edited files or paraphrases hunks line by line.
- If you genuinely don't know why the change is being made, that's a signal to ask the user, not to write a vague message around the gap.
- Include issue or ticket references when the user has mentioned them.
- Don't pad: a one-line subject is correct for a genuinely trivial change. The rule is no missing why, not mandatory essays.

**Red flags that you're about to violate this:**

- "I'll just summarize what the diff does."
- "The change is self-explanatory, the filename is enough."
- "I don't actually know why this was needed, but 'fix bug' covers it."
- "Listing the modified functions makes the message look thorough."
- "It's a small commit, the message doesn't matter."
