### Alert on Scheduled Pipeline Failures

NEVER add a scheduled (cron) pipeline without wiring its failures to somewhere humans actually look. A scheduled job has no built-in audience — if its failure doesn't notify anyone, the job's real behavior is "works until it silently doesn't."

- Every scheduled workflow gets an on-failure notification step: `if: failure()` posting to the team's chat channel, opening/updating an issue, or paging — matched to how much the job matters. "Whoever happens to check the Actions tab" is not a notification channel.
- Beware default routing: most platforms notify the last committer of the workflow file, who may be a bot or long gone. Send failures to a team destination, not a person.
- Write cron times in UTC on purpose: add a comment translating to the team's timezone (`cron: '0 7 * * *'  # 07:00 UTC, 2 a.m. US Central — before business hours`). Avoid `0 0` and other on-the-hour favorites; offset by a few minutes to dodge platform congestion.
- Add `workflow_dispatch:` alongside every `schedule:` so the job can be run on demand when someone needs to verify it actually works (and so it can be tested before merge).
- Know the platform's auto-disable rules: GitHub suspends scheduled workflows after 60 days of repo inactivity. For low-traffic repos, say so to the user — the job needs either a keep-alive or external scheduling.
- If the scheduled job is load-bearing (backups, cert renewal, data refresh), prefer alerting on missing success over alerting on failure: a heartbeat/dead-man's-switch catches the runs that never started, which failure notifications structurally cannot.

**Red flags that you're about to violate this:**

- "The schedule and the script are done; that's what was asked for."
- "If it fails, it'll show up in the Actions tab."
- "GitHub emails people about failed runs anyway."
- "It's just a nightly cleanup; failures aren't urgent."
- "I'll add alerting once we see whether it's flaky."

### Build Once, Promote the Same Artifact

Build each release artifact exactly once, then promote that identical artifact — by digest or checksum — through test, staging, and production. NEVER write a pipeline where a deploy stage rebuilds from source, because a rebuild is a different artifact, and a different artifact is untested by definition.

- Structure the pipeline as build → test → promote: one build job produces the image/package, pushes it to a registry or artifact store, and outputs its immutable identifier; every later stage consumes that identifier. Deploy jobs contain no compile, bundle, or `docker build` steps.
- Pass the artifact by content address, not by name: an image *digest* (`@sha256:...`) or a checksummed file — not a `:latest` tag, not even a version tag, which can be repushed. The digest is the proof that staging and production ran the same bytes.
- Use the platform's artifact mechanism (or a registry) to carry outputs between jobs; never have a downstream job re-derive what an upstream job already built and tested.
- Rollback must mean redeploying a previously built, previously verified artifact fetched from the store — never rebuilding an old commit during an incident.
- Stage-specific configuration goes in at deploy time (env vars, config layers, mounted files), not bake time. If staging and production need different *builds*, that's a design problem to raise, because it makes "tested in staging" unverifiable for production.
- If the existing pipeline rebuilds per stage, don't extend the pattern when adding stages — flag it and propose consolidating to a single build with promotion.

**Red flags that you're about to violate this:**

- "Each job checks out and builds; that's the standard self-contained job pattern."
- "Rebuilding from the same commit produces the same artifact anyway."
- "Wiring the registry push and digest output is overkill for this pipeline."
- "Production needs a different build flag, so it gets its own build."
- "We can always rebuild any old version if we need to roll back."

### Don't Bump CI Timeouts to Hide Slowness

NEVER raise a CI job or step timeout to make a job that is timing out pass. A timeout firing is a signal that something got slower or hung; raising the limit silences the signal without touching the cause.

A timeout is an alarm, not a constraint to be negotiated with. Treat a newly-hit timeout exactly like a failing test.

- When a job hits its timeout, profile it first: compare step durations against a recent passing run and identify which step grew or hung.
- Look for the usual suspects: a hung process waiting on input, a test making real network calls, a retry loop against a dead endpoint, dependency resolution that stopped hitting cache.
- Fix the slowness at the source — kill the hang, mock the network call, restore the cache — and leave the timeout where it is, so it can catch the next regression.
- If runtime grew for a legitimate, explained reason (a genuinely larger test suite, a new build target), raise the timeout by the measured amount plus modest headroom, and say in the PR description what grew and why.
- Never remove a timeout entirely. A job with no timeout and a hang holds a runner hostage until the platform's ceiling kills it, hours later.
- Do not relocate the problem by splitting the slow step into a separate job with a huge timeout. That is the same bump wearing a disguise.

**Red flags that you're about to violate this:**

- "The job just needs a little more time."
- "CI runners are probably slow today; doubling the timeout is harmless."
- "I'll bump it now and investigate the slowness in a follow-up."
- "There's no time to profile the build; the user wants this merged."
- "Other jobs in this repo have 90-minute timeouts, so 45 is conservative."

### Don't Narrow CI Triggers to Go Green

NEVER shrink what CI tests in order to make it pass. That includes adding `paths` or `paths-ignore` filters to workflow triggers, narrowing the test command's target directory, adding `--ignore`/`--exclude`/`deselect` flags, or tightening branch filters — when the motivation is that something inside the excluded scope is failing.

Making CI green by narrowing what it sees is not fixing anything. It is deleting the measurement and keeping the dashboard.

- When a test or check fails, the failure is the work item. Fix the code, or report why you can't.
- Only add path filters as a deliberate performance optimization on a passing pipeline, with the rationale stated in the PR description — never in the same change that "fixes" a red build.
- Never exclude a test file, directory, or glob from the test command to get past a failure. If a test is genuinely obsolete, deleting it is a decision for the user, made explicitly, not a side effect of a CI flag.
- If you change any trigger, filter, or test-selection expression, list in the PR exactly what stopped being tested as a result. If you can't enumerate it, don't make the change.
- Treat workflow YAML diffs that reduce scope as requiring more scrutiny than application code, not less.

**Red flags that you're about to violate this:**

- "These tests are slow and failing, so excluding them improves the pipeline."
- "That directory is legacy code; it doesn't need CI anymore."
- "The workflow shouldn't even trigger for this kind of change."
- "I'll scope the test run down now and broaden it again later."
- "The failing tests aren't related to what this PR is about."

### Fail CI on New Warnings

Pipelines must treat new warnings as failures. ALWAYS enable warnings-as-errors in CI for the toolchains that support it, and NEVER weaken an existing warnings-as-errors setting to get a build passing.

A warning that can't fail the build will be read by no one and fixed by no one, until the day it stops being a warning.

- Wire it at the tool level: `eslint --max-warnings 0`, `tsc` with strict options, `-Werror` for compilers, `python -W error` or `filterwarnings = error` in pytest config, `RUSTFLAGS="-D warnings"`, `mvn -Werror`. Prefer the tool's config file over a CI-only flag so local runs fail the same way.
- When your change introduces a warning, the fix is in the code: migrate off the deprecated call, add the type, address the lint. Suppressing it (`# noqa`, `@SuppressWarnings`, `eslint-disable`) requires a justification comment at the suppression site explaining why the warning is wrong *here* — not why it's inconvenient.
- For an existing codebase with a warning backlog, don't flip everything to fatal in one PR (that just gets reverted). Ratchet instead: fail on warnings in changed files, snapshot the current count and fail on increases, or enable per-rule as each category reaches zero. The invariant to enforce is "no new warnings," immediately.
- Never respond to a warnings-as-errors failure by removing or loosening the flag, raising `--max-warnings`, or adding the warning's category to an ignore list. That converts a build failure into a permanent blind spot.
- Treat deprecation warnings from dependencies as scheduled future breakage: if you can't fix one now, surface it to the user as a tracked item rather than silencing it.

**Red flags that you're about to violate this:**

- "It's only a warning; the build still works."
- "I'll bump max-warnings from 0 to 3 since my change adds 3."
- "This deprecation won't bite until the next major version, which is ages away."
- "The strict flag is what's broken here, not my code."
- "Everyone ignores these warnings anyway, so failing on them is theater."

### Fail CI When Zero Tests Run

A test step that executes zero tests must fail. NEVER add `--passWithNoTests`, `--allow-empty`, or any equivalent flag, and never wrap a "no tests found" error in `|| true`. An empty test run almost always means the tests got disconnected from the runner — passing on empty is configuring CI to never mention it.

- When CI reports "no tests found," that is the bug to fix: check the glob/`testMatch` pattern against actual filenames, the working directory, the marker/tag filter, and recent renames. The tests are usually still there; the runner just can't see them.
- Configure runners to be strict where they aren't by default: keep pytest's exit-code-5 behavior (or use `pytest-error-for-skips`-style strictness), avoid `passWithNoTests` in jest config as well as CLI, and for runners that exit zero on empty, add an explicit count assertion.
- Belt-and-suspenders for load-bearing suites: have the test step emit the executed-test count and assert a floor, e.g. parse the JUnit XML or summary line and fail if `tests="0"` — or if the count dropped by an implausible fraction since the last run on the default branch.
- Sharded and filtered runs deserve special suspicion: a per-shard "this shard had no tests" is sometimes legitimate, but the *total* across shards must be nonzero — assert at the aggregation step, not per shard.
- The narrow legitimate case for pass-on-empty is a monorepo path-filtered job where "this package had no changes and has no tests to run" is expected. Even then, prefer skipping the job entirely (so it reports "skipped," which is honest) over running it and reporting "passed."

**Red flags that you're about to violate this:**

- "The error literally suggests --passWithNoTests; it's the documented fix."
- "This package doesn't have tests yet, so empty should pass for now."
- "The suite obviously has tests; a zero-test run can't really happen."
- "I'll allow empty runs to unblock the pipeline and fix the glob later."
- "Exit code 5 isn't a real failure; it's pytest being pedantic."

### Gate Production Deploys Behind Environments

NEVER create a pipeline step that deploys to production without binding it to a protected environment with an approval gate. A merge means the code passed its checks; it does not mean anyone decided to ship it.

- Every deploy job must declare its target: `environment: production` (GitHub), a protected environment (GitLab), a manual-approval stage (Jenkins/CircleCI/Azure). Production credentials must live as environment-scoped secrets, retrievable only by jobs bound to that environment — never as repo-wide secrets a feature branch workflow can read.
- When you add the `environment:` binding, tell the user which protection rules to enable in repo settings (required reviewers, deployment branch restriction to the default branch), because those rules are settings, not YAML, and the YAML alone gates nothing.
- Auto-deploy on merge is fine for preview and staging environments. The promotion from staging to production is where a human approval belongs.
- Add `concurrency:` to the deploy job so two merges can't deploy to the same environment simultaneously or out of order.
- If the user explicitly wants continuous deployment to production with no manual gate, implement it only after confirming that's the intent, and pair it with the compensating controls that make CD sane: deployment branch restrictions, concurrency control, and a documented rollback step in the same workflow.
- Never remove or weaken an existing environment gate to "unblock" a deployment. A gate someone is waiting at is functioning, not malfunctioning.

**Red flags that you're about to violate this:**

- "Deploying on every merge is just continuous deployment; that's best practice."
- "The approval step makes the demo clunky."
- "It's a small team; everyone who can merge is allowed to deploy anyway."
- "The environment setting is just a label; I'll skip configuring it."
- "The release is urgent and the approval gate is what's blocking it."

### Investigate Flaky CI Before Retrying

NEVER respond to an intermittent CI failure by retrying it — manually, with a `retry:` key, or with a retry-wrapper action — until you have investigated what actually failed. "It passed on re-run" is an observation, not a diagnosis.

Retries convert a visible problem into an invisible tax: slower pipelines, higher CI bills, and real regressions that slip through because failures are presumed flaky.

- When a job fails intermittently, pull the logs from the failing run first. Identify the exact test or step, the error, and the difference from passing runs (timing, ordering, environment).
- Look for the classic causes before declaring flakiness: shared state between tests, time/timezone dependence, network calls to real services, port collisions, unpinned dependency or image versions, and resource exhaustion on the runner.
- If you find the root cause, fix it in the code or test, not in the pipeline.
- If you cannot find the root cause in the time available, say so explicitly and report what you ruled out. Recommend quarantine-with-a-ticket as a human decision; do not silently add retry config.
- Never add a blanket retry to a whole job or workflow. If a retry is ever justified (a documented-unreliable external dependency you cannot remove), scope it to that single operation and comment why.
- One green re-run proves nothing. If you claim something is fixed, the evidence is the cause you found, not the color of the latest run.

**Red flags that you're about to violate this:**

- "It passed when I re-ran it, so the failure was spurious."
- "This test is known to be flaky; everyone just retries it."
- "Adding a retry wrapper is a pragmatic fix while the team is busy."
- "The failure is probably infrastructure, so there's nothing to investigate in the code."
- "Three attempts should be enough to get past this reliably."

### Keep CI Commands Matched to Local Dev

CI must run the same entrypoints developers run locally. NEVER write a bespoke build, test, or lint invocation directly into pipeline YAML when the repo has a canonical command (`make test`, `npm run lint`, `./gradlew check`, a `justfile` or `tox.ini` target) — and never "fix" CI by adding flags in the YAML that local runs won't get.

When CI and laptops run different commands, "works on my machine" and "works in CI" become two unrelated facts, and one of them is always a surprise.

- Before writing any workflow step, find the repo's existing entrypoints: `Makefile`, `package.json` scripts, `justfile`, `tox.ini`, `composer.json`. The CI step should be that entrypoint, verbatim: `run: make test`, not a reconstruction of what you think make test does.
- If no canonical entrypoint exists, create one (a Makefile target or package script) and call it from both documentation and CI — don't let the workflow YAML become the only place the real command lives.
- CI-specific needs go through supported seams, not forked commands: environment variables (`CI=true`, which most tools already honor), a config file the tool reads everywhere, or an entrypoint parameter (`make test JOBS=2`). The command itself stays shared.
- When you need to change how tests run — add a flag, exclude a path, bump a timeout — change it in the shared entrypoint or tool config so laptops and CI move together. A flag added only in YAML is drift with a commit hash.
- If you find existing drift while working on the pipeline, flag it and propose consolidating to the shared entrypoint; don't extend the divergence.

**Red flags that you're about to violate this:**

- "I'll just write the jest command directly; it's clearer than indirection through make."
- "This flag is only needed in CI, so the YAML is the natural place for it."
- "The Makefile is crusty; I don't want to touch it."
- "CI needs slightly different behavior, so a slightly different command makes sense."
- "Copying the command from another repo's workflow is faster than reading this repo's scripts."

### Keep Secrets Out of CI Logs and Artifacts

NEVER print credentials, tokens, or their derivatives in CI, and never upload artifacts that contain them. A CI log is a published, retained, searchable document — treat every line you emit as visible to everyone who can see the repo, indefinitely.

- Do not debug auth failures by printing the secret: no `echo $TOKEN`, no `env` dumps, no `printenv`, no `cat .env` or config files containing credentials. Debug with shape, not value: check length (`${#TOKEN}`), check presence (`[ -n "$TOKEN" ]`), print a checksum, or compare against expected prefixes.
- Do not rely on platform masking to save you. Masking matches the registered literal; base64, URL-encoding, JSON-embedding, string-splitting, and derived values all sail through. `::add-mask::` is defense in depth, not permission to print.
- Keep `set -x` out of any script region that handles credentials; wrap sensitive sections in `set +x` / `set -x`. Use `curl -sS` not `curl -v` for authenticated requests.
- Upload artifacts by explicit allowlist of the files you mean (`path: dist/app.tar.gz`), never the whole workspace (`path: .`). Before adding an upload step, ask what credential-bearing files earlier steps wrote into the workspace — `.env`, `.npmrc`, `.git/config` with embedded tokens, kubeconfigs, cloud CLI caches.
- Verify build artifacts don't embed secrets injected at build time: a frontend bundle that inlined a privileged key is a leak with a CDN.
- If a secret does hit a log or artifact, that's an incident, not a cleanup: deleting the log/artifact comes second; rotating the credential comes first. Say so to the user immediately.

**Red flags that you're about to violate this:**

- "I'll print the env vars just to see what the job is actually getting."
- "GitHub masks secrets in logs automatically, so it's safe."
- "It's a private repo; the logs aren't really public."
- "Uploading the whole workspace makes debugging the failure easier."
- "I'll add set -x temporarily and remove it after this run."
- "It's base64 in the log, so it's not readable anyway."

### Key CI Caches on Real Inputs

ALWAYS construct CI cache keys from a hash of the files that determine the cached content, and NEVER cache something whose staleness CI can't detect. A cache with a static key is not an optimization; it's a time capsule that your tests run against instead of your code.

- Dependency caches must key on the lockfile: `key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}`, and equivalently `poetry.lock`, `Cargo.lock`, `go.sum`, `Gemfile.lock`. If the lockfile changes and the key doesn't, the key is wrong.
- Use `restore-keys` prefixes only for partial-match fallback where the job rebuilds on top of the restored content (e.g., compiler caches). Never use a fallback for content the job treats as authoritative, like an installed dependency tree it won't reinstall.
- Never cache build outputs, test results, or anything the pipeline exists to produce and verify. Caching the thing you're measuring is measuring the cache. Use artifacts for passing outputs between jobs — artifacts are tied to the run; caches leak across runs.
- When a cache-related step misbehaves, fix the key expression — do not "simplify" the key by dropping the hash, and do not solve it by caching more aggressively.
- If you suspect a stale cache is masking a failure, bump a version prefix in the key (`v1-` to `v2-`) to force a cold run and verify the pipeline still passes from scratch. A pipeline that only passes warm is broken.
- Include the toolchain in the key when the cached content is toolchain-specific (Python minor version, compiler version), or restored content will silently mismatch the runtime.

**Red flags that you're about to violate this:**

- "A static key means more cache hits, which means faster CI."
- "The hashFiles expression is what's erroring, so I'll just remove it."
- "Caching the build output will save us the whole compile step."
- "The cache is probably fine; nobody's complained."
- "I'll cache node_modules directly so we can skip npm install entirely."

### Make Release Pipelines Safe to Rerun

ALWAYS write release automation so that running it a second time — after a partial failure, or by accident — either completes the release correctly or exits cleanly as a no-op. NEVER write a release step whose second execution errors on the first execution's side effects or publishes duplicates.

Release pipelines fail mid-run as a matter of course. Rerunnability is not a nice-to-have; it is the recovery mechanism.

- Make each side-effecting step check-then-act: skip tagging if the tag already exists *and points at the right commit*; skip publishing if this exact version is already in the registry; skip release creation if the release exists. "Already done" is success, not an error.
- Fail loudly on conflicts: if the tag exists but points at a *different* commit, that's not a skip, that's a stop-everything error. Idempotent does not mean conflict-blind.
- Order steps so the points of no return come last: validate, build, and test everything before the first publish; push the tag and announce only after artifacts are durably uploaded.
- Never auto-increment the version to dodge an "already exists" error. Same release, same version — a rerun that mints v1.4.3 because v1.4.2 half-exists has created a second problem.
- Derive the version from a single source (the tag, or one version file) rather than computing it independently in multiple steps, so a rerun can't disagree with itself.
- State in the PR how the pipeline behaves when rerun after each side-effecting step. If you can't answer that for a step, the step isn't done.

**Red flags that you're about to violate this:**

- "The release job only runs once per version, so reruns don't matter."
- "If it fails, someone can clean up by hand."
- "I'll bump the patch version on retry so the publish doesn't collide."
- "Checking whether the tag exists is extra complexity for an edge case."
- "The happy path works; failure handling can come later."

### Make Workflow Changes Testable Before Merge

NEVER merge a new or modified CI workflow that has never executed. If the trigger only fires on the default branch (`schedule`, `workflow_run`, `release`), you must create a way to exercise the logic before merge — untested YAML is untested code, and for these triggers the first run happens in production.

- Add a `workflow_dispatch:` trigger alongside `schedule:` so the job can be run manually from the PR branch (where the platform supports dispatching from branches) and so the on-call human can rerun it later. This costs one line and should be the default for every scheduled workflow.
- For logic-heavy workflows, put the logic in a script (`scripts/nightly-cleanup.sh`) that the workflow merely invokes. Scripts can be executed and tested from the PR; inline run-block logic cannot.
- Validate what's validatable pre-merge: run the YAML through the platform's linter or schema check (`actionlint`, `circleci config validate`, `gitlab-ci-lint`) and confirm every `secrets.*` and `vars.*` reference names something that exists.
- Temporarily triggering the workflow with `push:` or `pull_request:` on the feature branch to smoke-test it is legitimate — but removing that temporary trigger before merge must be part of the change, stated in the PR.
- In the PR description, state how the change was tested. If the honest answer is "it wasn't and can't be," say that explicitly and tell the user the first scheduled run needs to be watched — don't let an unexecuted workflow merge silently.

**Red flags that you're about to violate this:**

- "The YAML looks right; this trigger pattern is standard."
- "There's no way to test scheduled workflows, so merging is the test."
- "It's just a cron job; worst case it fails overnight and we fix it tomorrow."
- "The PR checks are green." (They tested the code, not this workflow.)
- "I copied this from a workflow that works."

### Never Delete Failing CI Checks

NEVER delete, comment out, disable, or rename a CI job, step, or check because it is failing. A red check is a report about the code; removing the check changes the report, not the code.

The job of CI is to fail when the code is wrong. Making it stop failing without making the code right is concealment, not progress.

- When a check fails, read the logs, find the root cause in the code, and fix that. The workflow file is almost never where the bug is.
- Do not achieve deletion by other means: commenting out the job, removing it from a `needs:` chain so nothing depends on it, renaming it so branch protection loses track of it, or moving it to a workflow that never triggers. These are all the same violation.
- If a check is genuinely obsolete (tests a deleted feature, duplicates another job), say so explicitly, show the evidence, and let the user decide to remove it. Obsolescence is a human call.
- If a check is broken (the tool itself crashes, not the code under test), report the breakage with logs. A broken check gets fixed or explicitly retired — not quietly dropped in an unrelated PR.
- Never bundle check removal into a feature PR. If removal is ever approved, it gets its own commit with its own explanation.

**Red flags that you're about to violate this:**

- "This check has been failing for a while, so it's clearly not load-bearing."
- "The simplest way to get this pipeline green is to remove the failing job."
- "Nobody seems to maintain this check anyway."
- "I'll delete it now and we can re-add it once the errors are fixed."
- "The user asked for passing CI, and this is technically passing CI."

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

### Never Disable Branch Protection to Merge

NEVER disable, weaken, or bypass branch protection to get a PR merged. That includes turning protection off (even "briefly"), removing checks from the required list, lowering the required-review count, dismissing reviews via API, using `gh pr merge --admin` or any admin/owner override, and pushing directly to a protected branch with a token that's exempt from the rules.

Branch protection is the enforcement layer for every other quality control. Lifting it doesn't skip one gate; it un-makes all of them, silently, at the exact moment they're blocking something.

- A merge blocked by a required check has one remedy: make the check pass by fixing the code. A merge blocked by required reviews has one remedy: get the reviews.
- If a required check is broken in a way that's genuinely not about this PR (the check's own infrastructure is down), report that to the user with evidence and let a human decide. The override decision and the override action both belong to humans with authority over the repo.
- "Disable, merge, re-enable" is not a workaround; it's the violation plus a cover-up step. The unprotected window applies to everyone, and the re-enable step gets forgotten under pressure.
- Never modify protection settings, rulesets, or CODEOWNERS as part of a task whose goal is merging something — even if you have the permissions. Having the token is not having the authority.
- If the user directly asks you to bypass protection, confirm they understand what's being skipped, state which checks will not have run, and proceed only on their explicit instruction — it's their repo, but the decision must be made with the facts visible.

**Red flags that you're about to violate this:**

- "I'll re-enable protection right after this one merge."
- "The failing required check is unrelated to this PR."
- "I have admin rights, so the override path is sanctioned."
- "The deadline justifies skipping review just this once."
- "Protection is misconfigured anyway; this rule shouldn't apply here."
- "The merge API suggests --admin as an option, so it's a supported flow."

### Never Hardcode Secrets in Pipeline YAML

NEVER write a credential as a literal in CI configuration — no API keys, tokens, passwords, signing keys, connection strings with passwords, or webhook URLs containing auth, in any workflow file, pipeline YAML, or script the pipeline checks out. Committed once means leaked permanently; git history does not forget.

- Reference secrets through the CI system's secret mechanism: `${{ secrets.NAME }}`, `$CI_VARIABLE`, a vault lookup, or the platform's OIDC federation. If the secret doesn't exist in the store yet, tell the user the exact name to create and stop — do not bridge the gap with a literal.
- This includes "temporary" values for testing the pipeline. There is no temporary in git history.
- If the user pastes a real credential into the conversation, do not transcribe it into any committed file. Use it only as instructed for the immediate task and recommend rotation, since it has now appeared in at least one log.
- Environment-specific config that isn't secret (region names, bucket names, service URLs) still doesn't belong inline in steps — put it in workflow-level `env:`, CI/CD variables, or environment definitions, so staging and prod differ in configuration, not in diverging copies of the YAML.
- Base64-encoding a secret, splitting it across variables, or hiding it in a committed `.env` file the pipeline reads are all the same violation with extra steps.
- If you find an existing hardcoded credential while editing a workflow, flag it immediately as a live incident requiring rotation — removing the line is not the fix.

**Red flags that you're about to violate this:**

- "It's a private repo, so committed secrets can't leak."
- "This is just a test token; I'll swap in the secret reference later."
- "The secrets store setup is the user's job; hardcoding unblocks the pipeline now."
- "It's only a staging credential."
- "I'll encode it so it's not sitting there in plaintext."

### Never Move Published Release Tags

NEVER repoint, force-push, or delete-and-recreate a release tag that has been published, and never overwrite a published artifact under an existing version. Once a version identifier has left the building, it is immutable — the only fix for a bad release is a new release.

A published version is a promise that this identifier means these exact bytes, forever. External lockfiles, checksums, mirrors, and caches all depend on it; repointing the tag breaks them in ways you can't see and they can't diagnose.

- A broken v2.3.0 gets fixed by v2.3.1 (or yanked/deprecated through the registry's mechanism, which marks it without mutating it). The bad version's existence in history is fine; versions are cheap, integrity violations aren't.
- No `git tag -f`, no `git push --force origin <tag>`, no deleting a remote tag to re-create it — even minutes after publishing. The window between "pushed" and "someone fetched it" is shorter than any pipeline re-run.
- Don't re-run a publish pipeline in overwrite mode against an existing version. If the release job supports `--force` republish, that flag is for disaster recovery by humans, not for fixing release mistakes.
- Floating convenience pointers are the one exception, and only when explicitly maintained as floating *aliases* of immutable releases: a major-version alias tag (`v2`) that tracks the latest `v2.x.y`, or a `latest` image tag. Move the alias; never the versioned tag it points to. Don't invent new floating tags without the user's sign-off.
- If a published tag has already been moved (by anyone), surface it immediately: downstream checksum failures are already happening or queued, and consumers may be flagging it as tampering.

**Red flags that you're about to violate this:**

- "The release is only ten minutes old; nobody has pulled it yet."
- "Re-tagging keeps the changelog clean — v2.3.1 for a one-line fix looks sloppy."
- "Same version, fixed contents — that's what users would want anyway."
- "The publish job has a force flag, so overwriting is clearly supported."
- "It's an internal package; we control all the consumers."

### Never Remove Pipeline Steps You Don't Understand

NEVER delete, comment out, or reorder a CI/CD pipeline step unless you can state specifically what it does and why it is no longer needed. "I can't see what this is for" is a reason to ask, not a reason to delete.

Pipeline steps frequently serve systems outside the repository — deploy targets, caches, compliance scanners, downstream consumers — so absence of in-repo references is not evidence of deadness.

- Before touching a step, establish its purpose: read its commands, check `git log` and `git blame` on those lines, search for the step name in docs and other workflows, and look at what runs would fail without it.
- Treat suspicious-looking steps as the most likely to be load-bearing: unexplained `sleep`s (waiting on a service), curls to internal hosts (warmups, notifications, registrations), file copies to odd paths (consumed elsewhere), env exports with no in-repo readers.
- If after investigating you still cannot explain a step, leave it alone and report it: name the step, what you checked, and what you'd need to know. Let the user decide.
- If removal is genuinely justified, make it its own commit with the evidence in the message — never folded into an unrelated change.
- Reordering counts. Steps may depend on side effects of earlier steps even without declared dependencies.

**Red flags that you're about to violate this:**

- "Nothing in the repo references this, so it's dead."
- "This sleep is obviously a hack someone forgot to remove."
- "The workflow will be cleaner without these legacy steps."
- "It still passes locally without this step, so it's safe to drop."
- "Whoever needs this would have documented it."

### Never Run Untrusted PRs with Secrets

NEVER execute untrusted PR code in a workflow context that has secrets or write permissions. Specifically: never combine `pull_request_target` (or any privileged trigger) with a checkout of the PR's head ref followed by anything that executes PR-controlled code — builds, installs, tests, scripts, or linters with plugin loading.

The platform strips secrets from fork PRs on purpose. Every workaround that restores secrets to attacker-supplied code is the vulnerability, regardless of how standard the YAML looks.

- Default to plain `pull_request` for anything that builds or tests PR code. If a step inside it needs a secret, that step is in the wrong workflow.
- Use `pull_request_target` only for jobs that operate on PR *metadata* without checking out or executing PR code: labeling, commenting, assigning. If the job contains a checkout of `head.sha` or `head.ref`, stop.
- When a result from untrusted code genuinely needs privileges (posting coverage, publishing previews), split it: an unprivileged `pull_request` workflow produces an artifact; a separate `workflow_run` workflow with secrets consumes the artifact as *data only* — validating it, never executing scripts or binaries from it.
- Never interpolate attacker-controlled fields (`pull_request.title`, `head_ref`, issue bodies, commit messages) into `run:` scripts. Pass them through `env:` and reference the environment variable, which the shell treats as data.
- Treat "secrets are not available to fork PRs" as a design constraint to architect around, not an error to make go away. If the user asks for the unsafe pattern, explain the exfiltration path before doing anything.

**Red flags that you're about to violate this:**

- "Switching to pull_request_target fixes the missing-secrets error."
- "Our repo is small; nobody's going to attack our CI."
- "The token only has a few scopes, so the exposure is limited."
- "I saw this exact trigger-plus-checkout pattern in a popular repo."
- "We need coverage upload on fork PRs and this is the only way."
- "It's just echoing the PR title for the log."

### Never Swallow Exit Codes in CI

NEVER discard or override the exit code of a CI command to make a failing step pass. No `|| true`, no `|| echo`, no trailing `exit 0`, no `set +e`, no wrapping the command in a conditional that ignores the result.

A CI command's exit code is the only signal the pipeline has. Laundering it converts a working check into a decoration that runs, fails, and reports success.

- If a command fails in CI, fix the thing the command is checking. The exit code is the messenger, not the problem.
- Watch for accidental swallowing too: `cmd | tee log.txt` returns tee's exit code in plain sh; use `set -o pipefail` or capture the status explicitly. Multi-line `run:` blocks should start with `set -euo pipefail` so a mid-script failure cannot be shadowed by a later command succeeding.
- `|| echo "warning: X failed"` is not error handling. It is `|| true` with a guilty conscience.
- If a command is genuinely advisory (e.g., a metrics upload whose failure should not block merges), do not bury that decision in shell syntax. Surface it: tell the user, explain why it should be non-blocking, and let them approve before you change anything.
- Never swallow exit codes in test, lint, type-check, build, or security-scan commands under any circumstances. Those exit codes are the product.

**Red flags that you're about to violate this:**

- "This command's failure isn't related to what I was asked to do."
- "The step mostly works; the exit code is just noisy."
- "I'll log the failure instead of failing, so the information isn't lost."
- "Cleanup commands always fail in this environment, so or-true is pragmatic."
- "The pipeline needs to be green to merge, and this is one shell token away."

### Never Use Skip-CI to Dodge Checks

NEVER add `[skip ci]`, `[ci skip]`, `[no ci]`, `[skip actions]`, or any equivalent skip directive to a commit message, PR title, or push in order to avoid running checks that might fail. A check that never ran proves nothing; it just removes the evidence.

The pipeline exists to measure the commit. Skipping it doesn't make the commit good, it makes the commit unmeasured.

- If a check is failing, read the failure and fix the code. The skip directive is not part of any fix.
- Do not skip CI on "trivial" code changes. The pipeline decides what's trivial, not the commit author. Plenty of outages started as a one-line change that "couldn't possibly break anything."
- Legitimate skip uses are narrow: pure documentation commits in repos whose pipeline doesn't touch docs, or automated bot commits that would trigger infinite workflow loops. Even then, prefer `paths-ignore` configured in the workflow over per-commit directives, because workflow config is reviewed and per-commit strings are not.
- Never use a skip directive on a commit that will be merged or deployed. The last commit before a merge is exactly the one that must be tested.
- If CI is too slow and that's why skipping is tempting, say so and propose fixing the pipeline's speed. Don't route around it silently.

**Red flags that you're about to violate this:**

- "This change is too small to need CI."
- "The failing check is unrelated to my change, so skipping is harmless."
- "I'll skip CI on this commit and let the next one run the full suite."
- "CI takes 20 minutes and the user wants this merged now."
- "It's just a refactor; the behavior is identical."

### No Continue-on-Error in CI

NEVER add `continue-on-error: true`, `allow_failure: true`, `catchError`, or any equivalent failure-suppression flag to a CI step or job to make a failing pipeline pass. A step that fails silently is worse than a step that fails loudly, because it keeps failing while everyone stops looking.

The pipeline going green is a measurement of the code. Suppressing a step's exit status games the measurement without changing the code, which is concealment.

- When a step fails, read the failure output and fix the underlying code or configuration. The fix belongs in the code, not in the step's error handling.
- Do not reach the same outcome by other spellings: `failure-condition` overrides, try/catch around the build script, `if: always()` on downstream jobs to mask an upstream failure, or routing the step's exit code through a wrapper that ignores it.
- The only legitimate uses of failure suppression are steps that are *expected* to fail by design (e.g., uploading diagnostics after a failed run, canary jobs explicitly labeled experimental). If you believe a step qualifies, state the justification in the PR description and add a comment in the YAML explaining why suppression is intentional, and get the user's confirmation first.
- If a step fails for reasons outside the repo (an external service is down), report that finding. Do not encode "the internet was flaky today" permanently into the pipeline.

**Red flags that you're about to violate this:**

- "This step isn't critical to the build, so it's fine if it fails quietly."
- "I'll suppress it for now and circle back to the real fix later."
- "The failure looks environmental, so ignoring it is safe."
- "The user wants a green pipeline and this is the fastest way to one."
- "Other steps in this workflow already have continue-on-error, so it's the house style."

### Pin Actions and Images to Immutable Refs

ALWAYS pin third-party CI actions to a full commit SHA and container images to a digest. NEVER reference them by mutable tags — `@v4`, `@main`, `:latest`, or bare version tags like `node:20`.

A mutable tag means the code your pipeline executes can change without any commit to your repo. That is both a reproducibility bug and a supply-chain hole.

- GitHub Actions: write `uses: org/action@<40-char-sha> # v4.1.2`, with the human-readable version in a trailing comment. The SHA is the pin; the comment is documentation.
- Container images: write `image: node:20.11.1-bookworm@sha256:<digest>`. The tag tells humans what it is; the digest is what actually gets pulled.
- Never resolve a pin by guessing or from memory. Look up the SHA for the release tag from the action's repository, or the digest from the registry, and record where it came from in the PR.
- If an existing workflow uses floating tags, don't silently churn it in an unrelated PR — flag it to the user as a supply-chain risk and offer to pin everything in a dedicated change.
- When a pinned action needs updating, update the SHA and the version comment together so they never drift apart.
- First-party actions referenced from within the same trusted org may follow that org's existing convention; everything third-party gets a SHA.

**Red flags that you're about to violate this:**

- "The action's README says to use @v4, so that's the supported way."
- "Tags basically never move; SHAs are paranoid."
- ":latest means we always get the bug fixes for free."
- "The SHA makes the YAML ugly and hard to review."
- "I'll use the tag for now and pin it properly later."

### Scope CI Token Permissions Minimally

NEVER grant a CI workflow broad permissions to fix a scope error. Resolve `Resource not accessible` by adding the single missing scope to the single job that needs it — not `permissions: write-all`, not a PAT with every box checked, not an org-wide deploy key.

The workflow token's scopes define the blast radius of every compromise in your pipeline — bad dependency, hijacked action, injected input. Minimal scopes make those incidents small; `write-all` makes them total.

- Set a restrictive default at the workflow level — `permissions: { contents: read }` (or even `permissions: {}`) — and grant additions per job: the release job gets `contents: write`, the commenter gets `pull-requests: write`, and neither gets the other's.
- When a permission error appears, identify which API call failed and which scope it needs (the platform docs map calls to scopes), then add exactly that. If you can't determine the scope, say so — don't resolve uncertainty by granting everything.
- Don't substitute a personal access token to dodge `GITHUB_TOKEN` limits without flagging it: PATs outlive runs, span repos, and escape the per-job permission model. If one is genuinely required (cross-repo triggers), request minimum scopes and say why in the PR.
- For cloud access from CI, prefer OIDC federation with a role scoped to the specific repo and branch over long-lived static keys in secrets.
- Never widen permissions in the same PR as unrelated work. A scope grant is a security decision; make it a visible, one-line, explained change.
- When touching an existing workflow that has `write-all` or no permissions block (older defaults are broad), flag it and propose the minimal set based on what the jobs actually do.

**Red flags that you're about to violate this:**

- "write-all fixes it for sure; narrower might mean another failed run."
- "I'll grant everything now and tighten it once the workflow is stable."
- "It's our own pipeline; the token can't fall into the wrong hands."
- "The example in the action's README uses write-all."
- "A PAT just works everywhere; the GITHUB_TOKEN restrictions are a hassle."

### Use Concurrency Groups for Deploys

Every job that deploys to, migrates, or mutates a shared environment MUST declare concurrency control naming that environment. NEVER ship a deploy workflow where two runs can act on the same target simultaneously or complete out of order.

Deploys race by default: a slow run of an old commit can finish after a fast run of a new one, silently un-deploying the newer code.

- GitHub Actions: set `concurrency: { group: deploy-production, cancel-in-progress: false }` on the deploy job or workflow. GitLab: `resource_group: production`. Jenkins: `disableConcurrentBuilds()`. Key the group by target environment, so staging and production don't queue behind each other but two production deploys can never overlap.
- Choose the queued-run policy deliberately. For deploys, `cancel-in-progress: false` (queue and run latest after) is usually right; cancelling a deploy mid-flight can strand the environment half-updated. For PR test workflows, `cancel-in-progress: true` keyed by `${{ github.ref }}` is right — superseded test runs are pure waste. Don't copy one job's policy onto the other kind.
- Concurrency groups serialize runs but don't enforce ordering. If out-of-order completion matters (it does, for deploys), add a freshness guard in the deploy step: compare the commit being deployed against what the environment currently runs, and refuse to deploy an ancestor over a descendant.
- Apply the same rule to anything else that mutates shared state from CI: database migrations, infrastructure apply steps (terraform), cache-warming jobs, release publishing.
- If you find an existing deploy workflow without concurrency control, flag it — it has been racing this whole time, win or lose.

**Red flags that you're about to violate this:**

- "Merges are infrequent here; two deploys won't overlap."
- "The deploy step is fast, so the race window is tiny."
- "I ran the workflow and it deployed fine."
- "cancel-in-progress: true everywhere — newer is always better, right?"
- "The platform probably serializes runs of the same workflow automatically."
