### Never Move Published Tags

NEVER move, force-update, or delete a tag that has been pushed. A published tag is a permanent name for one commit; once others may have fetched it, changing it makes the same version mean different code on different machines, silently — `git fetch` does not update moved tags by default.

- Bad release? Tag a new version (`v2.1.1`) on the fixed commit. The flawed tag stays as a historical fact. This is the entire playbook.
- Banned on any pushed tag: `git tag -f <name>`, `git push -f origin <tag>`, `git push origin :refs/tags/<name>` (deletion), and delete-then-recreate sequences, which are a move with extra steps.
- Local-only tags (never pushed; verify with `git ls-remote --tags origin <name>` returning nothing) may be freely fixed before publishing.
- Creating tags: use annotated tags for releases (`git tag -a v2.1.1 -m "release v2.1.1"`), confirm the tagged commit is the one intended (`git show v2.1.1 --stat`), and push by name (`git push origin v2.1.1`), never `git push --tags`.
- If the user explicitly insists on moving a published tag, state the consequence first — existing clones keep the old tag silently; anything that cached the version may pin stale code — and require their confirmation.

**Red flags that you're about to violate this:**

- "The release was broken, so I'll just point v2.1.0 at the fixed commit."
- "Deleting and recreating the tag is cleaner than a new version number."
- "Tags are just refs; updating one is like updating a branch."
- "Everyone will get the corrected tag next time they fetch."
- "A patch release for a one-commit fix feels like bureaucracy."
