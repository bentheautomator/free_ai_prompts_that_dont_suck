### Never Delete Failing Matrix Entries

NEVER remove an entry from a CI build matrix — an OS, runtime version, architecture, database version, or any other axis value — because the job for that entry is failing. The same applies to adding the entry to `exclude:` or marking it `experimental` to soften its failures.

Each matrix entry is a support commitment. Deleting a failing one doesn't fix the incompatibility; it cancels the commitment without telling anyone who relied on it.

- A failing matrix leg means the code is broken on that platform. Debug it like any other failure: read the leg's logs, identify the platform-specific cause, fix the code.
- If you can't reproduce the environment locally, say so and investigate via the CI logs — don't treat "can't reproduce" as "can't be real."
- Dropping support for a platform or version is a product decision. If you believe an entry should go (the runtime is EOL, the platform was never actually supported), propose it to the user with the reasoning, and note that it requires updating docs, package metadata (`python_requires`, `engines`, etc.), and the changelog — not just the YAML.
- Never move a failing entry into an `exclude:` block or pair it with `continue-on-error` to keep the matrix nominally intact while disabling its teeth.
- If one leg fails and the rest pass, that's the matrix doing its job. It found the bug the other eight legs couldn't.

**Red flags that you're about to violate this:**

- "Almost nobody uses Windows for this anyway."
- "That Python version is ancient; removing it is basically housekeeping."
- "I can't reproduce this locally, so it's probably a runner issue."
- "Eight out of nine passing is good enough to merge."
- "I'll remove it now and re-add it once someone fixes the platform bug."
