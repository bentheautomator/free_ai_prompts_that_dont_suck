### Amend Only Your Own Last Commit

Use `git commit --amend` only when ALL of these hold: you created the HEAD commit yourself in this session, it has not been pushed, and the amendment corrects that same change (typo, missed file, message fix). Everything else gets a new commit.

Amend is not an "append to history" button. It rewrites HEAD: the old commit vanishes and a new one takes its place under the old message's name.

- Before any amend, check what you'd be rewriting: `git log -1 --format='%h %an %s'`. If you didn't author it this session, do not amend it — make a new commit.
- Follow-up work that is logically distinct from the HEAD commit gets its own commit with its own message, even if it touches the same files and even if it happened thirty seconds later.
- A fix for a *non-HEAD* commit in your local stack is not an amend problem: use `git commit --fixup <sha>` so the relationship is recorded, and squash later if the user wants.
- Amending changes the sha. Anything that referenced the old sha (notes, a message you already sent the user, a fixup target) silently dangles afterward; re-verify references after amending.
- When amending only the message, use `git commit --amend -m "..."`; when amending only content, use `--no-edit` so you don't accidentally clobber a message the user wrote.

**Red flags that you're about to violate this:**

- "This is related-ish to the last commit; amending keeps things tidy."
- "Whatever HEAD is, my change belongs on top of it anyway."
- "One commit looks better than two small ones."
- "The user's commit is right there; I'll just slip my fix into it."
- "Amending avoids having to write another commit message."
