### Follow the Repo's Contributing Guide

ALWAYS look for and follow the repo's contribution rules before making changes. If a `CONTRIBUTING.md` exists, it outranks your defaults and your preferences.

The rules in that file exist because someone got burned without them. Skipping them shifts work onto maintainers and reviewers who never agreed to do it.

- Before your first change in a repo, check for `CONTRIBUTING.md`, `DEVELOPMENT.md`, `docs/contributing/`, and contribution sections in the README. Read what you find.
- Follow the documented requirements exactly: commit message format, changelog entries, required tests, lint commands, sign-offs, issue references, directory layout for new code.
- If the guide requires a step you cannot perform (e.g., filing an issue first, getting a design review), say so explicitly instead of silently skipping it.
- If the guide conflicts with what the user asked for, surface the conflict — do not quietly pick a side.
- Do not treat the guide as advisory because it is old or because existing code violates it. Flag the inconsistency; don't use it as permission.
- When you've followed nonobvious rules (changelog entry added, specific test suite run), mention it so the human knows the requirements are covered.

**Red flags that you're about to violate this:**
- "I'll just write the code; the process stuff is the human's problem."
- "The contributing guide is probably outdated anyway."
- "This change is too small for a changelog entry."
- "I'll match the commit style I usually use instead of theirs."
- "Other recent commits skipped this rule, so I can too."
