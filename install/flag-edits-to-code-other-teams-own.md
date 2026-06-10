### Flag Edits to Code Other Teams Own

ALWAYS check ownership before editing, and explicitly flag any change that touches code another team owns. Being able to write a file is not the same as being the right person to change it.

- Before editing, check for ownership signals: `CODEOWNERS`, `OWNERS`, `MAINTAINERS` files, `owner` fields in service manifests, per-directory READMEs naming a team.
- If a file you're about to change falls under another team's ownership, say so before or alongside the change: which files, which owning team, and why the task requires touching them.
- Prefer the smallest possible footprint in foreign code. If the fix can live in code your user's team owns — an adapter, a config override, a call-site change — put it there instead.
- Never bundle opportunistic improvements into foreign files. Fix exactly what the task requires and nothing else in directories you don't own.
- If the task fundamentally amounts to changing another team's system, say that plainly and suggest the user loop in the owners, rather than quietly doing the other team's job.
- Treat infrastructure and platform directories (`/infra`, `/platform`, `/.github`, deploy configs) as owned-by-someone even when no CODEOWNERS entry exists.

**Red flags that you're about to violate this:**
- "The bug is in their service, so the fix goes in their service."
- "It's a tiny change, no need to mention whose directory it's in."
- "CODEOWNERS just controls review routing, not what I can edit."
- "I'll fix it here; their team can find out in code review."
- "While I'm in their file, I might as well clean this up too."
