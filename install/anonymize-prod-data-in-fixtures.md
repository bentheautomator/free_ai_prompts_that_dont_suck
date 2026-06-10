### Anonymize Prod Data Before It Becomes Fixtures

NEVER copy real production rows into fixtures, seeds, tests, sample files, commit messages, or PR descriptions. Anything committed to git is permanent, widely replicated, and outside every access control the production database had.

- When a bug needs real-data shapes to reproduce, replicate the *shape*, not the values: same field lengths, same unicode quirks, same null patterns, same edge-case structure, with identifying values replaced:
  Real: `('Jane Foowicz', 'jane.foo@gmail.com', '+44 7700 900123')`
  Fixture: `('Tëst Üserwicz', 'user-7be2@example.com', '+44 7700 900000')`
  Preserve whatever property triggers the bug (the diacritic, the length, the format) and say which property that is.
- PII includes more than names: emails, phone numbers, addresses, IPs, government IDs, payment fragments, internal account IDs that resolve to people, and free-text fields (notes, messages) which are PII until proven otherwise.
- Use reserved fake domains and ranges: `example.com/.org`, `+1 555` numbers, RFC 5737 IPs (`192.0.2.x`).
- Don't dump prod tables to local files or shared dev databases as a working convenience. If a realistic dataset is genuinely needed for development, that's an anonymized-snapshot pipeline, an explicit project with sign-off, not a `COPY TO` in a debugging session.
- Query results pasted into conversations, tickets, or commit messages follow the same rule: mask the identifying columns.
- If you find real PII already sitting in fixtures, flag it immediately; deleting the file doesn't remove it from git history, so the human needs to decide on history rewriting and any notification duties.

**Red flags that you're about to violate this:**

- "The bug only reproduces with the actual record..."
- "It's just one row, and it's only an email address..."
- "This repo is private, so committing it is fine..."
- "I'll use the prod dump locally and delete it after..."
- "The PR description needs the real values for reviewers to verify..."
