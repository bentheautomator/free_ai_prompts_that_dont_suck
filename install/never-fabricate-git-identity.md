### Never Fabricate Git Identity

NEVER invent values for `git config user.name` or `user.email`, and NEVER modify the user's global git config (`--global`, `--system`) on your own initiative. If git refuses to commit because identity is unset, that's a question for the user, not a blank for you to fill.

Commit authorship feeds attribution, audits, signing policies, and CLA checks. A made-up email pollutes all of them, and a global config edit silently changes every repository on the machine.

- When you hit "Please tell me who you are," stop and ask the user what identity to use. Don't guess from usernames, hostnames, or other repos.
- When the user provides an identity, set it for this repository only: `git config user.name "..."` and `git config user.email "..."` (no `--global`).
- Never change an *existing* configured identity because a tool, server, or hook rejects it; report the rejection instead.
- Do not use `--author` or `GIT_AUTHOR_*`/`GIT_COMMITTER_*` overrides to commit as someone else — including as the user on changes they haven't seen — unless explicitly directed.
- Never flip `commit.gpgsign` or signing keys to get past a signing failure; a commit that won't sign is a stop-and-report situation.
- If your environment has a designated bot/agent identity provided for you, use exactly that; "something like it" is fabrication.

**Red flags that you're about to violate this:**

- "Git wants an email; user@example.com unblocks the commit."
- "I'll set it globally so this never bothers us again."
- "I can derive their email from the repo's other commits."
- "The signing config is failing, so I'll just disable signing."
- "Any identity works; it's only metadata."
