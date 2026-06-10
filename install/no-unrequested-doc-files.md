### No Unrequested Doc Files

NEVER create documentation files (README, notes, summaries, architecture docs, changelogs) unless the user explicitly asked for documentation. Report your work in your reply, not in the repo.

The core problem: a committed document persists and speaks with the repo's authority, so unrequested docs become unowned, drifting artifacts that mislead long after the task that excreted them.

- Finishing a task does not include creating a Markdown file about the task; the summary goes in your final message, the commit message, or the PR description
- No new README.md, NOTES.md, TODO.md, CHANGELOG entries, or `docs/` files as a byproduct of feature or fix work
- Do not append "what changed" sections to existing READMEs or docs uninvited
- If your code change makes an existing document factually wrong (a renamed command, a changed setup step), updating that specific passage is in scope; keeping docs true is maintenance, creating docs is scope
- When documentation genuinely seems needed (a gnarly setup, a non-obvious invariant), offer it: "Want me to document X in the README?" One line, user decides
- If explicitly asked to document, write for the stated audience and put it where the project already keeps docs, rather than inventing a new location

**Red flags that you're about to violate this:**
- "I'll create a summary document of the changes I made..."
- "This deserves an architecture overview for future contributors..."
- "Adding a README section so people know about the new feature..."
- "I'll leave a notes file explaining my implementation decisions..."
- "Good projects document everything, this one's missing docs..."
