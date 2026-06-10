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

### Check Package Maintenance Before Adding

ALWAYS verify that a package is actively maintained before adding it as a dependency. Your knowledge of the ecosystem is frozen at training time; the package you remember as standard may have been abandoned years ago.

- Check the last publish date before installing: `npm view <pkg> time.modified`, `pip index versions <pkg>` plus the PyPI page, or the registry website. No release in 2+ years for an actively-evolving problem domain is a stop sign.
- Check for an explicit deprecation: npm prints deprecation notices on install — never ignore them, and never install a package you already know is deprecated.
- Glance at the repository: recent commits, whether issues get responses, whether the README announces abandonment or points to a successor. Many dead packages name their replacement; use it.
- Weigh maintenance against role. An abandoned 50-line leftpad-style utility is low risk; an abandoned HTTP client, auth library, or framework plugin is a future migration with a deadline you don't control.
- When you choose a package, state in one line when it last shipped and why you trust it. If the best-known package is dead and the alternatives are obscure, present that tradeoff to the user instead of silently picking either.

**Red flags that you're about to violate this:**
- "This is the standard library everyone uses for this."
- "I've seen this package in hundreds of examples."
- "The download count is huge, so it must be fine."
- "Checking the publish date is overkill for a quick install."
- "It worked in the tutorial, and the API won't have changed."

### Check Runtime Support Before Package Installs

ALWAYS check a package's minimum runtime requirement against the oldest runtime the project actually targets before adding or upgrading it. "It installs on my machine" only proves compatibility with the machine that matters least.

- Find the project's true floor first: the `engines` field, `.nvmrc`, `requires-python`, the Dockerfile's `FROM` line, and CI's version matrix. The constraint is the oldest of these, not whatever the dev shell runs.
- Check the package's floor before installing: `npm view <pkg> engines`, the PyPI page's "Requires: Python" line, or the package docs. For an upgrade, check the new version's floor — packages routinely raise it in majors and sometimes in minors.
- If the package's floor exceeds the project's, pick the newest package version that still supports the project's runtime (registries keep them all; `npm view <pkg>@'*' engines` shows the history) — or surface the conflict to the user.
- NEVER resolve the conflict by raising the project's runtime — editing `engines`, bumping the Dockerfile base image, or changing CI's version matrix — as a side effect of adding a package. A runtime upgrade is its own project with its own testing, decided by humans.
- Treat `EBADENGINE` and similar warnings as failures, not noise. A non-fatal warning at install time is frequently a fatal error at runtime on the older target.

**Red flags that you're about to violate this:**
- "It installed and ran cleanly, so compatibility is fine."
- "The engines warning is non-blocking; npm installed it anyway."
- "Everyone is on Node 22 by now."
- "I'll just bump the base image to make the requirement go away."
- "The latest version is the best version to install."

### Check the License Before Adding a Package

ALWAYS check a package's license before adding it as a dependency, and state the license in your summary of the change. License compatibility is a shipping requirement, not a legal nicety — the wrong license in the tree can mean the product cannot legally be distributed as-is.

- Check with one command: `npm view <pkg> license`, `pip show <pkg>` after install, `cargo add` output, or the registry page. Do this for every new dependency, every time.
- Permissive licenses (MIT, Apache-2.0, BSD, ISC) are generally safe to adopt without escalation. Note them and move on.
- Stop and ask the user before adding anything copyleft (GPL, AGPL, SSPL) to a project that isn't itself open source under a compatible license. AGPL applies even when the software is only served over a network, not distributed.
- Treat "no license," "UNLICENSED," custom licenses, and source-available licenses (BUSL, fair-source variants) as blockers requiring explicit human sign-off. No license means no permission.
- LGPL and MPL sit in between — usually workable with conditions (dynamic linking, file-level copyleft) that depend on how the project uses the code. Name the condition when you flag it.
- This applies to code you vendor or copy as much as packages you install. Pasting a function from a GPL repository carries the license with it.

**Red flags that you're about to violate this:**
- "It's on npm, so it's open source and fine to use."
- "License review is a lawyer problem, not an engineering step."
- "Everyone uses this package; the license must be permissive."
- "It's just a dev dependency, the license doesn't matter." (often true, worth confirming, never assuming)
- "I'll add it now; someone can audit licenses later."

### Declare Every Package You Import

NEVER import a package that isn't declared in the project's own manifest. "The import resolves" is not evidence of a dependency — in hoisted `node_modules` layouts, hundreds of undeclared transitive packages resolve by accident, and any of them can vanish or change version when a parent package updates.

- Before writing an import for a package, check it's in this project's `package.json` (`dependencies` or, for test/build code, `devDependencies`). In a monorepo, check the manifest of the specific workspace the file belongs to — a dependency declared in a sibling package doesn't count.
- If it's not declared but you need it, install it properly (`npm install <pkg>` / `pnpm add <pkg>`) so manifest and lockfile record it at a version the project controls.
- Don't import from a dependency's internals either (`lodash/internal/...`, deep paths into another package's `dist/`) — undeclared and unexported paths are both promises nobody made to you.
- The same rule outside JS: don't `import` a Python package just because it arrived as a transitive dependency of something in requirements. Declare what you use.
- When touching existing code, treat an undeclared import you find as a latent break worth mentioning — it will fail on the next dependency shuffle or a pnpm migration.

**Red flags that you're about to violate this:**
- "The import works, so the package is available."
- "It's already in node_modules; installing it again would be redundant."
- "Some other dependency brings it in, so it'll always be there."
- "Adding it to package.json is bookkeeping; the code runs fine."
- "It resolves in this workspace, so it must be declared somewhere."

### Diagnose Import Errors Before Installing

NEVER respond to a missing-module error by immediately installing the module. In an existing project, the most common cause is environmental — wrong interpreter, missing install step, wrong directory — and installing into the wrong environment masks the real bug while adding a stray copy.

- First, check whether the project already declares the dependency: look in `package.json`, `requirements.txt`/`pyproject.toml`, `go.mod`. If it's declared, the package is not missing — your environment is wrong, and installing again is the wrong move.
- Identify what actually executed: `which python` / `python -c "import sys; print(sys.prefix)"` to see if the venv is active; check whether the command should be `poetry run`, `pnpm exec`, or run from a different directory.
- For a fresh clone or new shell, the fix is usually the project's setup step — `npm install`, `poetry install`, activating the venv — not adding a package.
- In a monorepo, confirm which workspace owns the failing file before adding anything, and add the dependency to that workspace's manifest, not the root and not whatever directory you're standing in.
- Only when you've confirmed the package is genuinely absent from the project's declarations is installing it the right fix — and then it goes through the project's package manager, into the manifest, like any new dependency.

**Red flags that you're about to violate this:**
- "Module not found — installing it will fix this."
- "Fastest path to unblocking the script is pip install."
- "It's probably just not installed yet." (declared where? checked?)
- "I'll install it here; the environment details don't matter for now."
- "The error literally tells me what package to install."

### Don't Build on Deprecated Packages

NEVER choose a deprecated package for new code. Deprecated means the maintainers have formally told users to leave; building new functionality on it is creating migration debt on purpose.

- Read install output. If the package manager prints a `deprecated` warning for a package you just added, that's a decision point, not noise: identify the recommended replacement (usually named in the warning or the README) and use it instead.
- Before reaching for a package you "know" is standard, consider its era. If your knowledge of it comes from older tutorials, verify its current status on the registry page — the famous packages most likely to be deprecated are exactly the ones training data over-represents.
- Know the headline cases in JS: `request` (deprecated; use built-in `fetch`, `undici`, or `axios`), `moment` (maintenance mode; use `date-fns`, `dayjs`, or the `Temporal` API where available). Equivalent graveyards exist in every ecosystem.
- An existing deprecated dependency already in the project is a different situation: don't rip it out unasked, but don't expand its footprint either. Write new code against the modern alternative, and mention the migration opportunity.
- Deprecation warnings for transitive dependencies you didn't choose are informational — note them if asked about install output, but they don't block your task.

**Red flags that you're about to violate this:**
- "This package is the classic choice for this; millions of projects use it."
- "The deprecation warning is just noise; the install worked."
- "It's deprecated but it still functions, so it's fine for now."
- "The codebase already uses it somewhere, so adding more is consistent."
- "Switching to the replacement would mean learning a different API."

### Don't Depend on Git Branches

NEVER point a dependency at a mutable git ref — a branch name, a fork's `main`, or a bare repo URL that defaults to HEAD. A branch dependency means "whatever that branch says at install time," which is a different package every week and a build failure the day the ref disappears.

- Strongly prefer a released version from the registry. If the fix you need is merged but unreleased, first check whether a release is imminent (open issues/milestones often say) — waiting one release beats carrying a git dependency.
- If a git dependency is genuinely unavoidable, pin it to a full commit SHA, never a branch: `github:user/lib#a1b2c3d4...`, `git+https://...@<sha>`. A commit is immutable; a branch is a moving target.
- Treat fork dependencies as a loud, temporary exception: comment in the manifest why the fork is needed, link the upstream PR or issue you're waiting on, and note what removing it depends on. A fork URL without an exit plan becomes permanent.
- Never depend on a stranger's fork for convenience. Installing `random-user/lib#patched` executes whatever that account pushes, forever after. If the patch matters, fork it into an organization you control and pin the SHA there.
- When you encounter an existing branch-pinned dependency while working, flag it — it's a build outage with an unknown date attached.

**Red flags that you're about to violate this:**
- "The fix is on main; I'll install straight from the repo until it's released."
- "Pointing at the branch means we get future fixes automatically."
- "This fork has exactly the patch we need."
- "The lockfile will pin it anyway, so the branch ref is fine."
- "It's temporary — we'll switch back to the registry version soon."

### Don't Downgrade Packages to Match Old APIs

NEVER downgrade a dependency so that code written from your training-data knowledge of its API will run. The installed version is the project's decision; your memory of an older API is not a reason to reverse it.

- When your code fails against an installed package, treat your API knowledge as the suspect, not the package version. Check the installed version (`npm ls <pkg>`, `pip show <pkg>`) and write code for that version — consult its current docs, its type definitions in `node_modules`, or its changelog for what moved.
- A downgrade is only legitimate when the user asks for it, or when the new version has a genuine defect — and in the defect case, say what the defect is, link the evidence, pin precisely, and leave a comment explaining when the pin can come off.
- Watch for your own disguised versions of this move: adding a `<2` constraint while "fixing requirements," resolving a conflict by choosing the older side because you know its API, or scaffolding new projects with old majors because your examples use them.
- If the installed version genuinely can't do what's needed, the direction is forward (is there a newer version? a different package?) or a conversation with the user — never silently backward.
- After any version change you do make, state it explicitly in your summary: which package, which direction, and why. Version changes hidden inside "fixed the errors" are how downgrades slip through review.

**Red flags that you're about to violate this:**
- "This API worked in every example I know; the version must be the problem."
- "Downgrading is faster than rewriting the code for the new API."
- "v1 is more stable and widely used anyway."
- "I'll pin below 2.0 to keep things compatible."
- "The new major changed everything; reverting it simplifies the task."

### Don't Mix Package Managers

ALWAYS detect which package manager a project uses before running any install, add, remove, or script command — and use only that one. Introducing a second manager creates a second lockfile, and two lockfiles means two conflicting versions of the truth.

- Detect before acting: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm, `bun.lockb`/`bun.lock` → bun. The `packageManager` field in package.json is authoritative when present. The same applies outside JS: `poetry.lock` → poetry, `uv.lock` → uv, `Pipfile.lock` → pipenv.
- Use the detected manager for everything: installs (`pnpm add`, not `npm install`), script running (`yarn test`, not `npm test`), and exec (`pnpm dlx`, not `npx`). Script runners differ in how they resolve binaries and lifecycle hooks.
- If you accidentally generate a foreign lockfile (a stray `package-lock.json` in a pnpm repo), delete that foreign lockfile before committing. Never commit two lockfiles.
- Never "switch" a repo's package manager as a side effect of a task. Migrating managers is a deliberate project decision with its own PR.
- If no lockfile and no `packageManager` field exists, ask which manager the team uses rather than defaulting to npm.

**Red flags that you're about to violate this:**
- "npm install is the standard way to add a package."
- "The command failed under pnpm, so I'll try it with npm."
- "A package-lock.json appeared, but extra lockfiles are harmless."
- "yarn and npm are interchangeable for a simple install."
- "I'll use npx for this even though the repo uses pnpm."

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

### Don't Vendor Packages by Copy-Paste

NEVER copy a library's source code into the repository as a substitute for declaring it as a dependency. A pasted library is an invisible fork: no version, no security scanning, no upstream fixes, and usually a license violation.

- If the project needs a library, declare it in the manifest and install it. If the install fails, fix the install problem — don't route around the package manager by pasting its output.
- Needing one small function from a big library is not a paste license. Either take the dependency, or write your own genuinely original implementation of the small thing. Reproducing the library's implementation from memory is still copying, including its license obligations.
- If vendoring is truly required (offline builds, policy reasons, patched fork), do it properly and visibly: a dedicated `vendor/` directory, the exact upstream version and source URL recorded, the LICENSE file included, and a note on how to update. Vendoring is a documented decision, not a paste.
- Never strip or omit license headers and copyright notices from copied code. For most open-source licenses, keeping the notice is the main condition of being allowed to copy at all.
- If you find pasted-library code in the repo while working, flag it — it's an unpatched, unscannable dependency someone doesn't know they have.

**Red flags that you're about to violate this:**
- "The install is failing, but I can just inline the library's code."
- "We only need one function, so copying it in is leaner than a dependency."
- "I'll reproduce it from memory, so it's not really copying."
- "It's open source; that means I can paste it anywhere."
- "Putting it in utils/ keeps the dependency count down."

### Install Into the Correct Workspace

ALWAYS add a dependency to the manifest of the workspace whose code imports it. In a monorepo, "the install command succeeded" says nothing about whether the dependency landed where it belongs.

- Identify the owning workspace first: which package's source files will import this? That package's manifest gets the entry — not the root, not the workspace you happen to be standing in.
- Use workspace-targeted commands from the repo root: `npm install <pkg> -w packages/api`, `pnpm add <pkg> --filter @scope/api`, `yarn workspace @scope/api add <pkg>`. These work regardless of current directory and name the target explicitly.
- The root manifest is for repo-wide tooling only — the test runner, linter, build orchestrator shared by all packages. Application dependencies (HTTP clients, ORMs, loggers, UI libraries) in the root manifest are misfiled even if everything resolves.
- If the same library is needed by several packages, declare it in each package that imports it. Hoisting may store one physical copy; the manifests must still tell the truth per package.
- Never run a bare `npm install` from inside a workspace subdirectory in ways that spawn a nested `node_modules` or extra lockfile. Install from the root with workspace flags, and if a stray nested lockfile appears, remove it before committing.
- After installing, verify placement: check that the diff touched the intended package's manifest, not the root's.

**Red flags that you're about to violate this:**
- "I'm at the repo root, so npm install here is simplest."
- "It resolves from every package anyway thanks to hoisting."
- "I'll add it to the root so all the packages can share it."
- "The install worked from this directory, so the location is fine."
- "Which workspace owns this file doesn't change the command."

### Keep Dev Tools Out of Production Dependencies

ALWAYS file dependencies by where they're needed at runtime, not just install them. Anything used only to build, test, lint, or format the code goes in `devDependencies` (or the dev/test extra in Python) — `dependencies` is a claim that production cannot run without this package.

- Dev-flag the obvious tooling every time: test frameworks (jest, vitest, pytest), linters and formatters (eslint, prettier, ruff, black), type checkers and compilers (typescript, mypy), bundlers and build plugins (webpack, vite, esbuild), and type stubs (`@types/*`). Command forms: `npm install -D`, `pnpm add -D`, `poetry add --group dev`, or the `[dev]` extra in pyproject.
- The test is "does the code import or invoke this at production runtime?" — not "is it important." TypeScript is critical to the project and still a devDependency, because production runs the compiled output.
- Genuine runtime packages (the web framework, the database driver, the HTTP client your code imports) belong in `dependencies` — don't overcorrect and dev-flag something the server imports, which breaks production installs in the opposite direction.
- Edge cases follow the same test: a build tool invoked by a production start script is a runtime need; a CLI used only in CI is not. When a package serves both, `dependencies` wins.
- When you notice an obviously misfiled package while editing the manifest, mention it. Don't silently re-shelve someone else's entries, but don't leave the observation unsaid.

**Red flags that you're about to violate this:**
- "npm install jest — done."
- "The section doesn't really matter; it all ends up in node_modules."
- "This tool is essential to the project, so it's a real dependency."
- "I'll sort out dependency sections later; installing is the task."
- "requirements.txt is the place Python dependencies go." (all of them?)

### Match Import Names to Real Package Names

NEVER derive an install command from an import name. The name in `import x` and the name you give the package manager are different namespaces, and guessing the mapping installs the wrong package — or a typosquat planted to catch exactly that guess.

- Before installing to fix an ImportError, find the real distribution name from an authoritative source: the library's official documentation install section, its PyPI/npm registry page, or the project's existing requirements/manifest (the dependency may already be declared under its real name).
- Know that the mismatch is common, not exotic: `PyYAML`/`yaml`, `Pillow`/`PIL`, `opencv-python`/`cv2`, `scikit-learn`/`sklearn`, `python-dateutil`/`dateutil`, `beautifulsoup4`/`bs4`, `@google-cloud/storage` vs its import path. Treat every import-to-install translation as unverified until checked.
- Verify what you're about to install: check the registry page for the expected description, repository link, and download volume. A package whose page is empty, brand new, or unrelated to the library you want is a stop-everything signal.
- If the install succeeds but the import still fails, do not iterate through name guesses (`pip install pil`, `pip install pillow2`, ...). Each guess is another roll of the typosquat dice. Stop and look up the real name.
- The same applies in reverse: when writing requirements files from code, record distribution names, not import names.

**Red flags that you're about to violate this:**
- "The module is called yaml, so the package is called yaml."
- "I'll try installing it under a few likely names."
- "The install succeeded, so it must have been the right package."
- "No time to check the docs; the name is obvious."
- "pip found a package with that name, which proves it exists."

### Never Bypass Package Integrity Checks

NEVER disable the verification between your package manager and the code it downloads. No `strict-ssl false`, no `NODE_TLS_REJECT_UNAUTHORIZED=0`, no `--trusted-host` to silence TLS errors, no `verify_ssl = false`, and never delete or edit integrity hashes to make a lockfile error pass. These checks are the only thing confirming you're installing what the author published.

- A TLS failure during install means the secure channel can't be established. The fix is fixing the channel: configure the corporate proxy's CA certificate properly (`npm config set cafile`, `pip config set global.cert`, `REQUESTS_CA_BUNDLE`), not turning verification off.
- An `EINTEGRITY` or checksum mismatch means the downloaded bytes don't match the recorded hash. Treat it as a real signal: clear the local cache and retry (`npm cache clean --force`), check whether a mirror is misbehaving, and if the mismatch persists from the canonical registry, stop and escalate to the user — do not "fix" the hash.
- Never set bypasses globally or persistently (in `.npmrc`, `pip.conf`, CI images, or shell profiles). A bypass that outlives the error disables verification for every future install nobody is watching.
- If the user explicitly directs a bypass for a controlled environment, scope it to the single command, state what protection is off while it runs, and leave nothing persistent behind.
- "The install must succeed" is never sufficient justification. An install that succeeds unverified has not succeeded; it has gambled.

**Red flags that you're about to violate this:**
- "It's a certificate issue; disabling strict-ssl is the standard workaround."
- "I'll add --trusted-host so pip stops complaining."
- "The integrity hash is stale; removing it will let the install proceed."
- "This is just a corporate proxy thing, not a real security problem."
- "I'll set the env var globally so this never blocks us again."

### Never Delete Lockfiles to Fix Installs

NEVER delete a lockfile (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Cargo.lock`, `poetry.lock`, `Gemfile.lock`, `composer.lock`) to make an install error go away. Deleting it re-resolves every dependency in the project to new versions, which is a silent, unreviewed mass upgrade — not a fix.

- When an install fails, read the actual error. Resolution conflicts name the packages involved; fix those specific packages, not the whole tree.
- If the lockfile is genuinely corrupted or out of sync with the manifest, regenerate it with the package manager's intended command (`npm install` against the existing lockfile, `pnpm install --fix-lockfile`) and then diff the lockfile to confirm only the expected entries changed.
- If you must regenerate from scratch as a last resort, say so explicitly, explain why, and tell the user that every dependency version may have changed and the result needs full testing before merge.
- Never combine lockfile deletion with `rm -rf node_modules` as a reflex "clean slate" ritual. Clearing `node_modules` is fine; deleting the lockfile is the part that changes what gets installed.
- A lockfile-only diff with thousands of changed lines after fixing one package is a sign you did this. Stop and investigate.

**Red flags that you're about to violate this:**
- "The classic fix for this error is deleting the lockfile and reinstalling."
- "The lockfile is probably stale, regenerating it is harmless."
- "A fresh resolution will pick compatible versions automatically."
- "Stack Overflow's top answer says to remove package-lock.json."
- "It's just a lockfile, the real versions are in package.json."

### Never Hand-Edit Lockfiles

NEVER edit a lockfile directly. `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Cargo.lock`, `poetry.lock`, `Gemfile.lock`, and friends are machine-generated output with internal invariants (integrity hashes, resolution keys, dependency graphs) that only the package manager can keep consistent.

- To change a version, edit the manifest (`package.json`, `pyproject.toml`, `Cargo.toml`) or use the manager's command (`npm install pkg@4.2.1`, `cargo update -p pkg`, `poetry update pkg`), then let the tool rewrite the lockfile.
- Never change `version`, `resolved`, or `integrity` fields in a lockfile by hand, even if the edit looks trivially correct. You cannot compute the integrity hash, so the file becomes internally inconsistent.
- Never "fix" a lockfile parse error or schema complaint by editing the file. Regenerate it through the package manager and check the diff.
- If a lockfile entry must change for a transitive dependency, use the supported mechanism: `overrides` in package.json, `resolutions` in yarn, `pnpm.overrides`, or `cargo update -p` — then run install so the lockfile is rewritten by the tool.
- Treat any task plan that includes "edit the lockfile" as a planning error. The correct verb for lockfiles is "regenerate," never "edit."

**Red flags that you're about to violate this:**
- "It's just JSON, I'll bump the version field directly."
- "Editing the lockfile is faster than running the whole install."
- "I'll update the resolved URL too, so it stays consistent."
- "The install environment isn't available, so I'll write the lockfile change manually."
- "Only one entry needs to change, no need to involve the package manager."

### Never Patch Installed Packages in Place

NEVER fix anything by editing files inside `node_modules`, `site-packages`, `vendor/bundle`, or any other package-manager-managed directory. Those directories are disposable: your edit is invisible to git, absent everywhere else, and erased by the next install — leaving the bug "fixed" in the report and present in reality.

- First, exhaust the options that don't modify the package: upgrade to a version with the fix, work around the bug at the call site, or use the library's extension points (hooks, adapters, configuration).
- If the package itself must change, use persistent patch tooling: `npx patch-package <pkg>` (commits a diff applied on every install), `pnpm patch` / `yarn patch` for those managers. The patch file lives in the repo, survives reinstalls, and is visible in review.
- Pair any patch with an upstream path: link the upstream issue or PR in a comment, so the patch is a bridge to a released fix rather than a permanent fork hidden in a patches directory.
- For exploration and debugging, temporarily editing `node_modules` to add a `console.log` is fine — but it is debugging, not fixing. Revert it, and never let "the edit made the tests pass" become the delivered solution.
- If you catch yourself writing to a path containing `node_modules/` or `site-packages/` as part of a fix, stop: whatever you're doing will not exist tomorrow.

**Red flags that you're about to violate this:**
- "The bug is right here in the library file; I'll fix it directly."
- "Editing node_modules is the fastest way to unblock this."
- "Tests pass after my change, so the issue is resolved."
- "It's a one-line fix; full patch tooling is overkill."
- "I'll note somewhere that this needs to be re-applied after installs."

### No npm audit fix --force

NEVER run `npm audit fix --force`. The flag's documented behavior is installing breaking changes — major-version jumps and downgrades across the tree — in exchange for a lower warning count. That trade is never yours to make unilaterally.

- Plain `npm audit fix` (no `--force`) is acceptable: it only applies updates within existing semver ranges. Run it, then diff the lockfile and confirm the changes are the expected patches/minors.
- For advisories that remain, triage instead of forcing: `npm audit` shows which dependency path each advisory enters through. A vulnerability in a dev-only build tool that never sees production input is a different priority than one in request parsing — say which kind each is.
- Fix stubborn advisories surgically: upgrade the specific direct dependency that pulls in the vulnerable version, or use a targeted `overrides` entry pinning the one transitive package to a patched version. One advisory, one deliberate change.
- If a fix genuinely requires a major-version migration, present that to the user as a migration — with the breaking changes named — not as a forced flag inside a cleanup commit.
- Audit warnings in install output are not your task unless the user made them your task. Report them; don't reflexively eliminate them, and never at the cost of unreviewed major bumps.

**Red flags that you're about to violate this:**
- "npm itself is suggesting the --force command."
- "Getting vulnerabilities to zero is obviously the right outcome."
- "The breaking changes warning is boilerplate; it'll probably be fine."
- "I'll just run it and see if the tests still pass."
- "Security fixes justify whatever version changes they require."

### No curl-Pipe-bash Package Installs

NEVER install software by piping a remote script into a shell (`curl ... | bash`, `wget -qO- ... | sh`, `iwr ... | iex`). Executing unread remote code with shell privileges, unversioned and unrecorded, is the failure mode package managers were invented to prevent.

- Prefer the tool from a real package manager first: the system one (`apt`, `dnf`, `brew`, `winget`), the language one (`npm`, `pipx`, `cargo install`), or the project's published packages. Most popular tools are available this way; check before defaulting to the script.
- If no packaged form exists, download a pinned release artifact instead: a specific version from the project's releases page, with its published checksum verified (`sha256sum -c`) before anything executes or gets moved onto PATH.
- If the install script is genuinely the only path, download it to a file first, read it, then execute the reviewed copy — and record the version/URL/date somewhere in the repo if the project depends on the tool. Never pipe directly from network to shell, and never pipe into `sudo`.
- In Dockerfiles and CI, the bar is higher, not lower: these run unattended forever. Pin the artifact version and verify the checksum in the build step, so the build fails loudly if the upstream bytes change.
- The vendor recommending the one-liner doesn't change the analysis. It's their happy path for adoption, not a security posture for your infrastructure.

**Red flags that you're about to violate this:**
- "This is the official install command from their homepage."
- "Everyone installs this tool with the curl one-liner."
- "It's a trusted project; the script is fine."
- "Reading the script first is paranoia for a setup step."
- "I'll add sudo since the script needs to write to /usr/local."

### No Duplicate-Purpose Packages

ALWAYS check what the project already uses for a job before installing a library for that job. Adding your preferred package alongside the project's existing choice creates two configurations, two bug surfaces, and a permanent "which one do we use here?" question.

- Before installing anything, search the manifest and the code: does this project already have an HTTP client, date library, validation library, state manager, test assertion library, logging library, or utility belt? `grep` the imports; read `package.json`. The existing choice wins by default.
- Use the project's library even if you know a different one better. Your fluency with `axios` is not a reason to add it to a `got` codebase — read the existing wrapper, copy the prevailing call patterns, and stay consistent.
- If the existing library genuinely can't do what's needed, say so specifically ("X doesn't support streaming uploads; options are...") and let the user choose between extending, replacing, or adding. Replacement and addition are project decisions, not side effects of a feature.
- Check transitive availability cautiously: the answer to "the project has no date library" is sometimes that dates are handled with native APIs on purpose. Absence of a library can also be a decision.
- This includes micro-duplicates: don't add a second UUID generator, deep-equal, or classnames-joiner because the existing one's import path didn't come to mind.

**Red flags that you're about to violate this:**
- "axios is the standard choice for HTTP requests."
- "I'm more reliable writing zod schemas, so I'll use zod here."
- "It's a small library; having both is harmless."
- "The existing wrapper looks complicated; a fresh client is cleaner."
- "This file doesn't import the other library, so there's no conflict."

### No Global Package Installs

NEVER install project tooling globally. No `npm install -g`, no `pip install` outside a virtualenv, no `gem install` into the system Ruby for something the project uses. If the project needs a tool, the project's manifest must say so.

- Add tools to the project: `npm install -D <tool>` and run it via `npx <tool>` or a package.json script; `pip install` inside the project's venv and record it in requirements/pyproject; `cargo add`, `bundle add`, etc.
- For one-off executions, prefer ephemeral runners over installation: `npx <tool>`, `pnpm dlx`, `pipx run`, `uvx`. These leave no global state behind.
- Never use `pip install --break-system-packages` or `sudo pip install`. If pip refuses because the environment is externally managed, the fix is a virtualenv, not force.
- Never use `sudo` with any language package manager. If an install seems to need root, the install location is wrong.
- If a global tool already exists on the machine, don't rely on it — the project must work on a machine that doesn't have it. Check the manifest, not the PATH, to determine what's available.
- Exception: tools the user explicitly asks to install globally for their own machine-wide use. Confirm that's the intent before using `-g`.

**Red flags that you're about to violate this:**
- "I'll install it globally so it's available on the PATH."
- "It's just a CLI tool, it doesn't need to be a project dependency."
- "Global install is quicker than editing package.json."
- "pip is refusing, so I'll pass --break-system-packages."
- "sudo will get around this permissions error."

### No --legacy-peer-deps as a Fix

NEVER use `--legacy-peer-deps`, `--force`, or equivalent conflict-suppression flags as the response to a peer dependency error. These flags do not resolve the conflict; they install a combination of packages that one of the authors has explicitly declared incompatible.

- Read the ERESOLVE output. It names the package, the peer it requires, and the version you have. Resolve the actual mismatch: pick a version of the new package that supports your existing peer, or upgrade the peer deliberately as its own reviewed change.
- Check whether a compatible version exists before concluding there's a real conflict: `npm view <pkg> peerDependencies` per version, or read the package's compatibility table.
- If no compatible version exists, report that honestly: "this package does not yet support React 19; the options are wait, use an alternative, or knowingly force it." Forcing is the user's call to make, not yours.
- Never add `--legacy-peer-deps` to `.npmrc`, CI config, or package.json scripts. That converts a one-time judgment call into permanent project-wide suppression of all future conflicts.
- If an override is genuinely the right tool (a package's peer range is stale but it works), use a targeted `overrides`/`resolutions` entry for that one package, with a comment, instead of a global flag.

**Red flags that you're about to violate this:**
- "ERESOLVE errors are usually fixed with --legacy-peer-deps."
- "The peer ranges are probably just outdated; forcing it will be fine."
- "I'll add the flag to .npmrc so the install works everywhere."
- "This is a known npm quirk, not a real incompatibility."
- "Getting the install green is the priority; compatibility can be checked later."

### No New Package for Stdlib Tasks

NEVER add a dependency for functionality the standard library or built-in runtime APIs already provide. A dependency is a liability you adopt forever, not a feature you gain once.

Before any install command, ask: can the standard library do this in under ~20 lines? If yes, write those lines.

- Check the stdlib first: `fetch` instead of axios/node-fetch, `crypto.randomUUID()` instead of uuid, `structuredClone` instead of lodash.cloneDeep, `fs.rm` instead of rimraf, `Array.prototype.flat` instead of array-flatten, Python's `pathlib`/`json`/`urllib`/`dataclasses` instead of their package equivalents.
- If you only need one function from a utility library, write that function. `isEmpty`, `debounce`, `chunk`, and `pick` are each under ten lines.
- It is acceptable to add a dependency for genuinely hard problems: timezone math, parsers, cryptography you should not hand-roll, protocol implementations. The bar is "nontrivial to implement correctly," not "exists on npm."
- If the project already depends on a utility library, use it — do not write a parallel implementation. This rule governs adding NEW dependencies only.
- When you decide a new dependency is justified, say so explicitly and name what the stdlib lacks.

**Red flags that you're about to violate this:**
- "There's probably a package for this..."
- "Lodash is what most tutorials use here."
- "Installing it is faster than writing the helper."
- "It's a tiny package, it won't hurt."
- "axios has a nicer API than fetch."
- "Everyone depends on this anyway."

### No Wildcard Version Ranges

NEVER declare a dependency with an unbounded version: no bare names in requirements.txt, no `*`, no `latest`, no open-ended `>=x` without an upper bound. Every dependency you add gets a bounded constraint anchored to the version you actually installed and tested.

- After installing, record what you got. JS: keep the caret range the package manager writes (`^4.2.1`) and ensure the lockfile is committed. Python without a lockfile-based tool: write `requests>=2.32,<3` or pin exact (`==2.32.3`) in requirements.txt — never a bare `requests`.
- Anchor to reality: the lower bound is the version you tested, not `0` and not a guess. Run `pip show <pkg>` / `npm ls <pkg>` to read the installed version instead of inventing one.
- The upper bound is the next major. Majors are documented breakage; an unbounded range pre-approves breakage sight unseen.
- If the project uses a lockfile tool (npm, pnpm, poetry, uv, cargo, bundler), the lockfile provides exactness — the manifest range can stay flexible, but it still must not be `*` or `latest`, because the manifest is what governs the next re-resolution.
- When generating a manifest for example code or a scaffold, pin there too. Scaffolds get copied into production verbatim.

**Red flags that you're about to violate this:**
- "I'll leave the version off so it always gets the newest."
- "latest keeps the project up to date automatically."
- "I don't know the current version, so an open range is safer."
- "This is just a quick script; versioning it is ceremony."
- "The README's install command doesn't specify a version either."

### Pin Packages in Dockerfiles and CI

ALWAYS pin an explicit version for every package installed in a Dockerfile, CI workflow, or provisioning script. These installs run outside the lockfile's protection and re-resolve on every build — unpinned, they are a different build every week.

- Dockerfiles: `RUN pip install awscli==1.33.0`, not `RUN pip install awscli`. Base images get specific tags (`FROM python:3.12.4-slim`), never `latest` and never a bare major (`python:3`).
- CI workflows: pin tool installs (`npm install -g vercel@34.2.0`), pin action versions to a tag at minimum, and pin language setup steps to exact versions where the project depends on behavior (`node-version: 20.14.0`).
- Find the current version honestly before pinning: `npm view <pkg> version`, `pip index versions <pkg>`, or the registry page. Never invent a version number from memory — your recall of "current" is stale by definition.
- Linters, formatters, and scanners installed in CI must be pinned exactly. A floating linter version means PR checks change without any commit, which poisons trust in the whole pipeline.
- When you touch an existing Dockerfile or workflow that has unpinned installs, flag them. Don't silently re-pin someone else's lines without being asked, but say what you saw.

**Red flags that you're about to violate this:**
- "The quickstart installs it without a version, so that's the convention."
- "latest is fine for a build tool; it's not shipped to users."
- "Pinning means we'll fall behind on updates."
- "I don't know the current version, so I'll leave it floating."
- "The lockfile handles versioning for this project."

### Read the Changelog Before Major Version Bumps

NEVER upgrade a dependency across a major version boundary without first reading its changelog or migration guide for that major. A major version bump is a documented set of breaking changes, not a bigger number.

- Before any major bump, find the breaking-changes list (CHANGELOG.md, GitHub releases page, migration guide) and enumerate which entries touch this codebase. If you cannot access the changelog, say so and stop instead of upgrading blind.
- A deprecation warning is not an upgrade mandate. The supported response is usually a small code change on the current major, not a version jump. Fix the deprecated usage first; upgrade as a separate, deliberate task.
- When the user asks for the upgrade itself, do it as a migration: bump the version, apply every relevant change from the migration guide (config format, renamed APIs, changed defaults), and list which breaking changes you handled and which you verified don't apply.
- Never bundle a major upgrade into an unrelated task. "Fix the failing test" must not quietly include "and also move to webpack 6."
- Check the new major's minimum runtime requirements (Node version, Python version) against what the project and its CI actually run.

**Red flags that you're about to violate this:**
- "Upgrading to the latest version should resolve this warning."
- "The tests pass after the bump, so the breaking changes must not affect us."
- "Majors are mostly marketing; the API is probably the same."
- "I'll bump it now and we can deal with any issues if they come up."
- "The deprecation message says this is removed in v9, so I'll just install v9."

### Regenerate Lockfiles to Resolve Merge Conflicts

NEVER resolve a lockfile merge conflict by choosing hunks like source code. A lockfile is resolver output: the only valid post-merge lockfile is one the package manager generated from the merged manifest, not one assembled from pieces of two different resolutions.

- Resolve the manifest first. `package.json` (or `pyproject.toml`, `Cargo.toml`) conflicts are real merge decisions — combine both branches' dependency changes there, by hand, correctly.
- Then regenerate, don't merge, the lockfile. npm: run `npm install` with the conflicted lockfile present — npm detects the markers and rebuilds correctly from the merged package.json. Equivalent flow for pnpm/yarn. Cargo/poetry: checkout one side's lockfile (or delete it as the documented conflict procedure for that tool prescribes) and re-run the lock step so the tool rewrites it from the merged manifest.
- Never delete conflict markers from a lockfile manually and commit what remains — even if the result parses, no resolver has verified it.
- Validate before committing: a clean `npm ci` / `pnpm install --frozen-lockfile` run proves manifest and regenerated lockfile agree. If it fails, the manifest merge is wrong — fix that, regenerate again.
- Check the regenerated lockfile's diff covers both branches' intents: the package your branch added and the ones the other branch changed should all be present. A regeneration that silently dropped one side means the manifest merge dropped it first.

**Red flags that you're about to violate this:**
- "Conflict markers — I'll take ours for these hunks and theirs for those."
- "Both sides just added different packages, so I'll keep both blocks."
- "The merged file is valid JSON, so the conflict is resolved."
- "Hand-merging is faster than re-running the whole install."
- "Lockfile conflicts are mechanical; no need to involve the package manager."

### Run the Package Manager After Manifest Edits

NEVER treat a dependency change as a text edit. Any change to dependencies in `package.json`, `pyproject.toml`, `Cargo.toml`, `Gemfile`, or `go.mod` must be followed by running the package manager, so the lockfile re-resolves and the change actually takes effect.

- Prefer commands over edits in the first place: `npm install axios@1.7.0`, `poetry add requests@^2.32`, `cargo add serde@1.0.200`, `go get pkg@v1.7.0`. These update manifest and lockfile together, atomically.
- If you do edit the manifest directly (fine for complex changes like overrides or moving a dep between sections), immediately run the project's install command and confirm the lockfile changed accordingly.
- Before finishing, verify sync: the committed diff must touch manifest and lockfile together. Manifest-only dependency diffs are broken-by-construction — `npm ci` will reject them.
- Verify the change is live, not just written: `npm ls <pkg>` or `pip show <pkg>` should report the new version. Code tested before the install ran was tested against the old version; rerun anything that matters.
- If the environment prevents running installs (no network, sandboxed), say so explicitly and mark the change as requiring an install before merge — do not present a hand-edited manifest as a completed dependency change.

**Red flags that you're about to violate this:**
- "Bumping the version string is the whole change."
- "The lockfile will get regenerated by whoever installs next."
- "I edited package.json, so the new version is in place now."
- "Running the install takes a while; the edit itself is enough to commit."
- "Tests passed, so the version change works." (against which installed version?)

### Verify the Package Exists Before Installing

NEVER install a package whose existence and identity you have not verified against the registry. A plausible name is not a real name — hallucinated package names get registered by attackers specifically to catch this mistake, and installation alone executes their code.

- Before any `npm install`, `pip install`, `cargo add`, `gem install`, or equivalent: verify the package on the registry first. Use `npm view <name>`, `pip index versions <name>` or the PyPI page, `cargo search <name>`, or fetch the registry URL directly.
- Verify identity, not just existence: does the description match what you expect? Does it have a real repository link, a plausible download count, and a version history older than a few weeks? A name that exists but was first published last month with no repo is a red flag, not a green light.
- Be especially suspicious of names you produced by analogy: "the Python version is probably called X," "the official SDK is probably `@vendor/thing`." Analogy is exactly how hallucinated names are formed.
- If you cannot verify (no network, registry unreachable), say so and present the install command for the user to vet — do not run it.
- Scoped/official packages: confirm the scope is the vendor's actual scope, not a lookalike.

**Red flags that you're about to violate this:**
- "The package is probably just called that."
- "It follows the usual naming convention, so this should be it."
- "The install will fail anyway if it doesn't exist."
- "I remember this package from somewhere."
- "It's the official SDK, the name is obvious."

### Weigh Bundle Size Before Frontend Packages

ALWAYS consider download weight before adding a dependency to code that ships to the browser. A frontend dependency is paid for by every user on every cold load; "it's just one package" is a per-visitor tax.

- Check the cost before installing: bundlephobia.com or `npm view <pkg> dist.unpackedSize` for a first approximation. For anything over a few tens of kilobytes minified+gzipped, justify the weight against the feature or find a lighter path.
- Prefer the platform first: `Intl` for date/number/relative-time formatting, `fetch` over HTTP client libraries, native `structuredClone`, CSS for animation before an animation library. The zero-kilobyte option is competitive surprisingly often.
- When a library is warranted, prefer the lighter peer (`date-fns` or `dayjs` over `moment`) and import so tree-shaking works: named imports from the package root or direct submodule imports — never a namespace import of the whole library for one function.
- Match scope to need: a single sparkline does not justify a full charting framework. Look for the focused package, or the heavyweight's modular entry points, before adopting the whole suite.
- This rule is about browser-bound code. Server-side and build-time dependencies have different economics — don't apply bundle anxiety to a CLI tool, and don't excuse a client package because "it's small on disk."

**Red flags that you're about to violate this:**
- "This is the most popular library for it, so it's the right choice."
- "One dependency won't move the needle on load time."
- "Bundle size is a performance optimization for later."
- "I'll import the whole library; the bundler probably tree-shakes it."
- "The dev server loads instantly, so the size is fine."
