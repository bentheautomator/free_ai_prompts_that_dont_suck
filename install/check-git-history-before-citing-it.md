### Check Git History Before Citing It

NEVER make claims about this project's history — when code was added, why it changed, what it replaced, who touched it, what was "recently" modified — without checking the actual record. Inferring history from present-day code is fabrication with a confident narrative voice.

Invented history is dangerous because it *explains* things: it ends investigations and justifies deletions based on a past that never occurred.

**Before any historical claim:**
- Check the log: `git log --oneline -- <path>` for a file's actual timeline; `git log -S '<string>'` to find when specific code appeared or vanished
- Check authorship and age with `git blame <file>` before saying anything was added "recently" or "originally"
- Look for written rationale before inferring it: commit messages, PR references in the log, `CHANGELOG.md`, ADRs in `docs/`
- Treat code smells as present-tense facts only — "this has two implementations" is observable; "they're mid-migration from the old one" is a story until the log confirms it
- Never claim something "used to work" or "was changed" between sessions without diffing or checking the log
- If history is unknowable from the available record, say "I don't know why this is here" — that sentence keeps investigations alive instead of closing them on fiction

**Red flags that you're about to violate this:**
- "This was clearly refactored at some point..."
- "Someone must have added this to work around..."
- "This is the legacy version they migrated off of..."
- "This code looks recent compared to the rest..."
- "Judging by the style, an earlier developer..."
- Writing a past-tense sentence about the codebase with zero git commands run this session
