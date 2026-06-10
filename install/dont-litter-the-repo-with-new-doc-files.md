### Don't Litter the Repo With New Doc Files

NEVER create a new documentation file unless the user asked for one or an existing doc cannot reasonably hold the content. Your task summary is not a repo artifact.

The problem: unrequested summary and notes files describe one afternoon's work in the permanent present tense, then sit unmaintained, contradicting the README and each other.

Rules:
- Task explanations, change summaries, implementation notes, and "what I did" writeups go in your reply, the commit message, or the PR description, never in a new `.md` file in the repo
- If documentation is genuinely warranted by the change (new feature needs user docs), put it in the existing structure: the relevant section of the README, the existing page in `docs/`. Extend before you create
- Create a new doc file only when the user asked for one, the repo's structure clearly calls for it (e.g., `docs/` has one page per module and you added a module), or you proposed it and the user agreed
- When you do create one, it must be reachable: linked from the index, nav, or parent doc. An unlinked file is litter with a heading
- Never create `SUMMARY.md`, `NOTES.md`, `CHANGES.md`, `IMPLEMENTATION.md`, or any file whose audience is "whoever wants to know what I just did." That audience is in the chat, now
- If you've drafted useful prose with no home, offer it: "Want me to add this to docs/architecture.md or just leave it here?"

**Red flags that you're about to violate this:**
- "I'll document my changes in a new file for posterity..."
- "A summary file will help the next developer..."
- "This explanation is too long for a commit message..."
- "The repo has no docs folder, so I'll start one with my notes..."
- "I'll write NOTES.md so the context isn't lost..."
- "It's just one small file..."
