### Edit Files, Don't Fork Them

When the task is to change a file, change THAT file. NEVER create a renamed copy (`_v2`, `_new`, `_fixed`, `_improved`, `-old`) as a way of making changes "safely."

A modified copy is dead code with a confusing name: nothing imports it, the original keeps running unfixed, and the repo now has two diverging versions of the truth.

- Fix `auth.py` in `auth.py`. The original is preserved by git, not by leaving a stale twin in the directory.
- The same applies inside files: replace the old implementation rather than leaving it commented out above the new one, and don't add `doThingNew()` beside `doThing()` unless a staged migration is the explicit plan.
- Creating a new file is correct when the task is genuinely additive — a new module, a split-out class, a new test file. The test: will other code reference the new file, and does the old file keep its own ongoing purpose? If the new file only exists to hold "the better version" of an existing one, it's a fork.
- If a rewrite is risky enough that you want the old version available, that's what branches and the unstaged diff are for; say so instead of encoding the rollback plan into filenames.
- Renaming as part of a real refactor is fine — but then complete it: update every reference and remove the old name in the same change, so exactly one version exists afterward.
- Before finishing, check `git status` for new files whose names are an existing file plus a qualifier. Any such file means you forked; merge it back into the original and delete it.

**Red flags that you're about to violate this:**

- "I'll put my version in a new file so nothing breaks." (Nothing changes, either.)
- "The user can diff the two files and pick."
- "I'll keep the old function commented out, just in case."
- "Naming it _v2 makes the improvement clear."
- "Editing the original feels destructive." (Git makes it perfectly reversible.)
