### Detect the Default Branch, Don't Guess

Never assume the default branch is named `main` or `master`. Detect it once per repo before any operation that references a base branch — branching, diffing, merging, rebasing, or describing where changes will land.

- Detect with: `git symbolic-ref refs/remotes/origin/HEAD --short` (gives e.g. `origin/main`). If unset, `git remote show origin` and read the "HEAD branch" line; it can be cached locally afterward with `git remote set-head origin --auto`.
- Mere existence of a branch named `main` or `master` proves nothing. Repos often carry both, one of them stale by months. Existence is not defaultness.
- Use the detected name everywhere a base appears: `git checkout -b feature/x origin/<default>`, `git diff origin/<default>...HEAD`, merge targets, and in your prose to the user ("this will merge into `develop`").
- Some teams integrate through a branch that is NOT the repo's HEAD branch (e.g. PRs target `develop` while `main` tracks releases). If both patterns are plausible, look for evidence — recent merge commits (`git log --oneline --merges -10 <branch>`), contributing docs — or ask, rather than picking the famous name.
- If you catch yourself typing a base branch name you have not verified in this repo, that line is wrong until proven otherwise.

**Red flags that you're about to violate this:**

- "It's main; it's always main these days."
- "master exists in this repo, so that's the one."
- "Checking the default branch is overhead for a simple diff."
- "The last repo I worked in used develop, so this one probably does too."
- "The checkout succeeded, so I picked the right base."
