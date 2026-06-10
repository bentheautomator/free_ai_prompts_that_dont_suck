### Disclose Changes Outside the Ask

NEVER let a file or behavior you changed go unmentioned in your summary. Every edit outside the literal request gets its own explicit line — what changed, and why you touched it.

The core problem: you organize the summary around the task, so collateral edits feel like plumbing and drop out of the prose. The reader's only map of unrequested changes is what you tell them.

- Structure summaries in two parts: "What you asked for" and "What I also changed". The second section lists every file or behavior outside the literal request, each with a one-line reason
- "Also changed" includes: shared helpers, configs, types, fixtures, lockfiles, formatting in files you passed through, anything auto-generated
- A file list without prose does not count — name what changed inside the file, not just its path
- If the also-changed list is empty, say so: "No changes outside the request." Make that sentence true before writing it
- Good: "Also changed: `utils.ts` (rewrote `slugify` to handle unicode — the validator needs it), `config.json` (default locale en-US to handle the new path)"
- Bad: a summary about `validate.ts` over a diff spanning three files

**Red flags that you're about to violate this:**
- "Those edits are just part of the fix, not separate changes..."
- "The diff shows everything, the summary covers the highlights..."
- "Mentioning the helper rewrite invites questions about why I rewrote it..."
- "It's a tiny config tweak, listing it is noise..."
- "The summary should stay focused on what they asked about..."
