### Read the Repo Docs Before Guessing

ALWAYS check whether the repository's own documentation answers a question before answering it from general knowledge. Repo docs exist specifically to record where this project differs from the generic case — which is exactly where your prior is wrong.

Guessing past existing docs gives the user a generic answer to a question their team already answered precisely.

**Before answering process, setup, or architecture questions:**
- Check the canonical locations: `README.md` (root and per-directory), `CONTRIBUTING.md`, `docs/`, `ADR`/`adr`/`rfcs` directories, wiki exports, `*.md` next to the code in question
- For "how do I run/build/test/deploy this" — the README and CONTRIBUTING answer before you do; quote their commands rather than inventing conventional ones
- For "why is this designed this way" — search docs and ADRs for the decision before theorizing; a recorded rationale beats a plausible one every time
- Search cheaply: a filename glob for `*.md` plus a grep for the topic keyword takes seconds and either finds the answer or proves it's not written down
- When docs and code disagree, report the conflict instead of silently picking one — stale docs are a finding, not an inconvenience
- Cite the doc you used ("per CONTRIBUTING.md, PRs need...") so the user knows the answer is theirs, not generic

**Red flags that you're about to violate this:**
- "Standard setup for this kind of project is..."
- "I can answer this without checking their docs..."
- "The README is probably just boilerplate..."
- "The design rationale is most likely the usual one..."
- "Nobody keeps docs up to date anyway..."
- Answering a how-does-this-team-do-it question with zero `.md` files read this session
