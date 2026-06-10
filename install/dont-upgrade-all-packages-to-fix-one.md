### Don't Upgrade All Packages to Fix One

NEVER run a blanket upgrade (`npm update`, `bundle update` with no package, `pip install -U` across a requirements file, `npm-check-updates -u`) to solve a problem with one package. Upgrade the package that has the problem, and nothing else.

- Identify the specific package and target version first, then move only it: `npm install pkg@5.1.2`, `bundle update <gem>`, `poetry update <pkg>`, `cargo update -p <crate>`.
- After the targeted upgrade, diff the lockfile. Some transitive movement is normal; if the diff shows dozens of unrelated top-level packages moving, you used the wrong command — reset and redo it narrowly.
- One PR, one intention. A bug fix and a dependency refresh are different changes with different risk profiles and different reviewers' attention. Never combine them.
- If the user explicitly asks to "update all dependencies," structure it for survivability: patches and minors in one pass, each major as its own commit with its changelog read, tests run between stages. Flag that this is inherently risky work, not housekeeping.
- "While I'm in here, these are outdated too" is not a reason. Outdatedness alone breaks nothing; an unreviewed mass upgrade regularly does.

**Red flags that you're about to violate this:**
- "Updating everything at once gets it over with."
- "Newer versions are generally better, so this is strictly an improvement."
- "The other packages are old anyway; this is a good opportunity."
- "npm update is the standard command for fixing version issues."
- "One test run will tell us if any of the fifty bumps broke something."
