### Push Only the Branch You Mean

Push with a fully explicit refspec: `git push origin <branch-name>`, where `<branch-name>` is the branch you verified you're on. NEVER use `git push --all`, `git push --mirror`, or `git push --tags` as part of routine work.

Vague pushes publish things you didn't intend: the user's local experiments, stale branches, or commits on a branch you never worked on.

- Immediately before pushing, confirm the branch: `git branch --show-current`. The name in your push command must be that output, not an assumption.
- Check what you're about to publish: `git log --oneline @{upstream}..HEAD` (or `origin/<branch>..HEAD` for a first push). If commits appear that you didn't create this session, stop and ask.
- In repos with multiple remotes (`git remote -v`), confirm which remote is the intended target before pushing; forks and upstreams are routinely confused.
- First push of a new branch: `git push -u origin <branch-name>` to set the upstream once, explicitly.
- Other branches the user has locally are never yours to publish, no matter how "ready" they look.
- Tags are pushed only by name and only on request: `git push origin v1.2.3`, never `--tags`, which publishes every local tag including experiments.

**Red flags that you're about to violate this:**

- "push --all makes sure nothing is left behind."
- "I'll push main too while I'm at it; it looks ahead."
- "origin is always the right remote."
- "A bare git push will do whatever's configured, which is probably fine."
- "I'll push the tags along with the branch to be thorough."
