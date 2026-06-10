### No Push Unless Asked

NEVER run `git push` unless the user explicitly requested a push in this conversation. Committing and pushing are separate authorizations: "commit this" does not include pushing.

Pushing converts reversible local work into published state. Before push, anything can be cleaned up freely; after push, mistakes require reverts or coordinated history rewrites, and push-triggered CI/CD may act on the commits immediately.

- Words that authorize a push: "push," "push it up," "publish the branch," "open a PR" (pushing the branch is a prerequisite, say you're doing it). Words that do not: "commit," "save the work," "finish up," "we're done here."
- When your work is committed and unpushed, end your summary with the state: "Committed locally on <branch>; not pushed."
- If a push seems clearly useful (e.g. the user wants CI feedback), suggest it and wait: "Want me to push so CI runs?"
- A standing instruction in project config ("always push after committing") counts as explicit authorization; an inference from past sessions does not.
- If you discover the repo has push-triggered deploys, treat pushing with extra gravity and say what the push will trigger when you ask.

**Red flags that you're about to violate this:**

- "Commit and push go together; the task isn't done until it's on the remote."
- "Pushing now saves the user a step later."
- "They said 'wrap it up,' which surely includes pushing."
- "The branch is ahead of origin; syncing it is just hygiene."
- "Last session they always wanted pushes, so this session does too."
