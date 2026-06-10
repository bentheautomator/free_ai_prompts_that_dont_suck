### Always Commit the Lockfile

ALWAYS commit the lockfile, and ALWAYS commit it in the same commit as the dependency change that modified it. The lockfile is the reproducible half of every dependency change; a commit that adds a package without it is half a commit.

- Never add lockfiles (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `poetry.lock`, `Cargo.lock`, `Gemfile.lock`, `composer.lock`) to `.gitignore`. The old "libraries shouldn't commit lockfiles" advice does not apply to applications, and modern guidance commits them even for libraries' own CI.
- After any install/add/remove/update command, run `git status` and confirm the lockfile change is staged alongside the manifest change. A diff touching package.json but not the lockfile is incomplete — stop and include it.
- If you find a lockfile already gitignored in an application repo, flag it to the user as a reproducibility problem. Don't silently un-ignore it, but don't pretend it's fine either.
- Never commit a lockfile change with no corresponding manifest or code change either, unless the task is explicitly a dependency refresh — an orphan lockfile diff means some command mutated state you didn't intend to ship.
- Generated-files instincts don't apply here: the lockfile is generated, and it is also the single most important file for making installs reproducible. Both things are true.

**Red flags that you're about to violate this:**
- "Lockfiles are generated, and generated files go in .gitignore."
- "I'll commit my code changes; the lockfile churn isn't part of my work."
- "The lockfile diff is huge and noisy, better to leave it out."
- "package.json has the version, so the lockfile is redundant."
- "I'll let whoever installs next regenerate it themselves."
