### Catalogue Behaviors Before Rewriting

NEVER begin reimplementing legacy code in a new stack, framework, or language until you have produced a written inventory of the old code's observable behaviors. The rewrite's spec is what the old code does, not what it appears to be for — and "what it does" must be enumerated, not intuited.

Before writing any replacement code:

- Build the behavior inventory from the old implementation: inputs accepted (including malformed ones it tolerates), outputs produced (exact shapes, formats, field names, ordering), side effects (writes, events, logs, metrics, emails), error behavior (which failures produce which statuses, messages, and partial states), and timing characteristics consumers may rely on.
- Read the old code's tests as recorded behavior, but don't trust them as complete — legacy test suites cover what once broke, not what consumers use.
- Mark every inventory entry as preserve, change deliberately, or unknown. "Unknown" entries get investigated or flagged to the user — they don't get silently resolved by whatever the new stack does by default.
- Present the inventory before the rewrite for anything non-trivial, so the user can veto wrong assumptions while they're still cheap.
- Implement against the inventory and verify against it: each preserved behavior should be checked in the new implementation, ideally by running old and new against the same recorded inputs.

If the inventory feels tedious, that's the tedium of the spec you were about to skip.

**Red flags that you're about to violate this:**
- "I understand what this module is supposed to do, I'll build that."
- "The new framework handles errors better, consumers won't mind the new shape."
- "These quirks are implementation details, not behavior anyone uses."
- "The old tests pass against my rewrite, so it's equivalent."
- "I'll handle discrepancies as they come up after the switch."
- "The cleanest design in the new stack is close enough to the old one."

### Check Flag State Before Deleting Feature Flags

NEVER remove a feature flag based on the age of the code. A flag is safe to delete only when its live state is verified: 100% enabled, for every customer, in every environment and region, with no targeting rules or opt-outs. That state lives in the flag system, not in the code, and you usually cannot see it.

Before removing any flag check:

- Ask the user for the flag's current state in the flag service or config: global percentage, per-customer overrides, per-region rules, and environment differences. If you cannot get this, do not remove the flag.
- Check which branch you'd be keeping. If the plan is to keep the "on" branch, confirm the flag is fully on; if any population is off, deleting the flag changes their product.
- Remember flags that are off everywhere: inlining the "on" branch for those launches a feature someone deliberately shelved. Verify the off branch isn't the real production behavior.
- Search for the flag name as a string across configs, infra code, experiment definitions, and docs — targeting rules and kill switches reference flags by name.
- When removal is verified safe, remove the flag, the dead branch, and the flag definition together, and say what evidence you relied on.

**Red flags that you're about to violate this:**
- "This flag is two years old, the rollout is obviously done."
- "The flag defaults to true, so everyone must have it on."
- "I'll keep the enabled path since that's clearly the intended behavior."
- "Stale flags are tech debt; removing them is always safe cleanup."
- "If some customer had this off, there'd be a comment saying so."
- "The feature shipped ages ago, the off branch can't matter."

### Check History Before Deleting Commented-Out Code

NEVER delete a commented-out block without first finding out why it was commented out rather than deleted. Someone made that choice deliberately; your job is to learn the reason before destroying the record.

For each commented-out block you want to remove:

- Run `git log -p` or `git blame` on those lines. Find the commit that commented them out and read its message. "Disable retry until vendor fixes rate limiting" means the block is dormant, not dead.
- Read any prose comment attached to the block. "DO NOT re-enable, corrupts session cache" is documentation of a landmine — deleting it re-arms the landmine for the next person.
- Check whether the block references things that still exist: live config keys, current endpoints, active feature names. A commented block full of live references is more likely paused than abandoned.
- If the history shows it was commented out as a quick disable during an incident, flag it to the user — the right fix may be re-enabling or properly removing, and that's their call.
- If the history shows pure clutter (commented out in the same commit that replaced it, years ago, no explanation needed), delete it freely. That's the case the hygiene rule was written for.

When you do delete, put the why in the commit message so the record survives in a findable form.

**Red flags that you're about to violate this:**
- "Commented-out code is always safe to delete, it's not even running."
- "If it mattered, it wouldn't be commented out."
- "Git history has it if anyone ever needs it."
- "I'll clean up all the commented blocks in this file in one pass."
- "There's no explanation, so it's clearly just clutter."

### Confirm Platform Retirement Before Dropping Support

NEVER remove platform-specific support code — polyfills, fallbacks, conditional builds, OS or browser or architecture branches — based on your judgment of which platforms are obsolete. The support matrix is a business decision recorded somewhere other than the code, and your training-data sense of "nobody uses that" is not it.

Before touching platform support code:

- Find the actual support matrix: browserslist config, minimum SDK/OS settings, build targets in CI, compatibility pages in docs, sales or contract requirements the user can check. A platform listed anywhere there is supported, full stop.
- Treat build configs as contracts. A 32-bit target in the build matrix, an old browser in browserslist, a low minSdkVersion: these are declarations that someone ships there, however unfashionable.
- Never drop a platform implicitly. Using an API unavailable on a supported platform, or deleting its fallback, is dropping the platform without saying so — the worst version, because nothing announces it until a user on that platform hits it.
- If you believe a platform should be dropped, propose it as its own decision: name the platform, what removing support saves, and who must confirm zero usage. The user takes it from there.
- When adding code, write to the declared floor, not your preferred floor. The supported platforms constrain which language features and APIs you may use, whether or not local tooling complains.

**Red flags that you're about to violate this:**
- "Nobody develops for that browser anymore."
- "That OS version is a rounding error in global market share."
- "This polyfill is for a platform that's been dead for years."
- "Modern devices all support this API, the fallback is pointless."
- "I'll use the new syntax; surely their toolchain targets something recent."
- "32-bit support in 2026 can't be real."

### Deprecated Is Not Unused

NEVER treat a deprecation marker as evidence that code is unused or removable. Deprecated means "stop adding callers"; it does not mean the existing callers left. Code is deprecated precisely because it still has consumers who need time to migrate.

When you encounter deprecated code:

- Do not delete it, even during cleanup tasks, unless the user explicitly asked for its removal.
- If removal is requested, enumerate the callers first: search the repo, search for the symbol name as a string (configs, templates, serialized data), and ask about consumers outside the repo — other services, other teams, public API users.
- Check the deprecation's terms. Annotations, docstrings, and changelogs often state a removal version or date ("removed in v5"). Removing earlier than the stated promise breaks consumers who planned around it.
- Distinguish the two ends of deprecation: marking something deprecated is cheap and safe; removing something deprecated is a breaking change that needs the same care as deleting any live API.
- Never route around deprecation the other way either: don't "fix" callers of deprecated code as a side effect of unrelated work. Migration to the replacement is its own task with its own risks.

If you need a mental model: deprecated code is on notice, not on the curb.

**Red flags that you're about to violate this:**
- "It's marked deprecated, so removing it is just finishing the process."
- "The replacement has existed for three years; everyone's migrated by now."
- "The IDE shows it struck through, it's basically dead already."
- "Deleting deprecated code is what cleanup means."
- "If callers still existed, the deprecation would have been reverted."
- "I'll remove it now and callers can switch to the new API when they notice."

### Don't Create a Third Style

NEVER introduce a new pattern into a codebase that already contains two versions of that pattern. A codebase mid-migration has an old style and a target style; your job is to detect both and write the target style, not your preferred style.

Before writing code in a legacy codebase:

- Survey how the codebase already does the thing you're about to do. If you find two patterns, that's a migration in progress — identify which is newer using `git log` on representative files, or check for a migration note in README, CONTRIBUTING, or ADR docs.
- Write new code in the target style exactly as the codebase practices it, even if you know a pattern you consider better. Your better pattern is a third style.
- Don't opportunistically convert old-style code you happen to be editing unless the user asked. If conversion is in scope, convert the whole unit the codebase migrates by (whole file, whole module), not just the lines you touched.
- If you genuinely cannot tell which style is the target, ask. One question beats guessing the direction of someone else's migration.
- If you believe both existing styles are wrong, say so in your summary as a suggestion. Do not act on it unilaterally.

The measure of consistency is not "is each function ideal" but "can a reader predict what the next file looks like."

**Red flags that you're about to violate this:**
- "Neither of their patterns is current best practice, so I'll use the right one."
- "I'll convert just these two functions since I'm editing them anyway."
- "Mixing styles is fine, it all works."
- "The new style everyone recommends now isn't either of these."
- "This file is already inconsistent, one more variant won't hurt."

### Don't Fix Weird Code That Works

NEVER "correct" code that looks strange but is not failing. Weirdness in old code is more often a workaround than a mistake: it encodes a bug someone already found, debugged, and defended against. Simplifying it reintroduces the original problem with the documentation destroyed.

Before changing any odd-looking construct:

- Run `git log -p` and `git blame` on the lines. A commit message like "fix timeout under load" attached to the weird part is your answer: it stays.
- Check if the weirdness correlates with a boundary: third-party API calls, time zones, encodings, file systems, floating point, specific browsers or OS versions. Boundaries are where workarounds live.
- Search the tracker or codebase for an issue/ticket ID near the code; weird code often has a paper trail one search away.
- If history explains nothing and the code is genuinely opaque, the safe move is to *add a comment asking why*, or flag it to the user — not to normalize it.
- If you must change it, state in your summary: "this construct may be a workaround; history shows X; the risk of simplifying is Y."

Distinguish failing from ugly. Fix code that produces wrong results. Leave code that produces right results in an ugly way, unless the user explicitly asked you to restructure it and accepts the risk.

**Red flags that you're about to violate this:**
- "This is clearly a mistake; no one would write it this way on purpose."
- "The standard library function does the same thing more cleanly."
- "This double-check is redundant, the condition can never be true twice."
- "I'll simplify this while I'm in the file."
- "Modern best practice is the opposite of what this code does."
- "There's no comment explaining it, so it can't be important."

### Don't Mass-Format Frozen Legacy Code

NEVER apply formatters or lint autofixes in bulk to legacy code, and never propose repo-wide normalization as cleanup. Mass-formatting frozen modules destroys git blame (often the only documentation old code has), applies unreviewed behavior-relevant "fixes" to untested code, and tramples deliberate freeze boundaries.

Rules of engagement:

- Respect the existing exclusion config absolutely: `.prettierignore`, `.eslintignore` equivalents, formatter exclusion lists, lint overrides per directory. An excluded path is a decision, not an oversight to correct.
- Never widen formatting beyond the lines you are editing. Touch a function, format that function if local convention says so; never let the editor or a save-hook reformat the whole file as a side effect of a one-line change.
- Treat lint autofix as code change, not formatting. Fixes that alter equality semantics, delete "unused" code, or reorder imports can change behavior; in untested legacy modules they are unreviewable risk applied at machine speed.
- Never reformat vendored or upstream-synced code. Reformatting it permanently breaks diffing against upstream, which is how that code gets updated.
- If repo-wide formatting is genuinely wanted, it's a project decision for the user: done in dedicated commits, with the formatting commit added to `.git-blame-ignore-revs` so blame survives, and with frozen or vendored paths excluded. Propose that — don't perform it.

**Red flags that you're about to violate this:**
- "While I'm here, I'll just run the formatter on the whole file."
- "Consistent formatting across the repo is an obvious win."
- "Lint autofixes are safe by definition."
- "This ignore file is probably just stale config."
- "The diff is big but it's all whitespace, nothing to review."
- "Old code deserves the same standards as new code."

### Don't Modernize Untested Code

NEVER upgrade idioms, syntax, or patterns in code that has no test coverage. Every "equivalent" modernization — callback to async, loop to stream, string format swap, equality operator change — carries small semantic deltas, and without tests those deltas ship silently.

Before modernizing anything:

- Check whether tests exercise the code you're about to touch. Look for test files referencing the module, then confirm the specific functions are actually covered, not just imported.
- If coverage exists, modernize and run the tests. That's the happy path.
- If coverage does not exist, you have two options: write characterization tests first (capture current behavior, including the weird parts, as assertions), or leave the idiom alone. "Leave it alone" is a fully acceptable outcome.
- Never bundle modernization into an unrelated change. If you're fixing a bug in an untested legacy file, fix the bug in the existing style.
- If the user explicitly asks for modernization of untested code, state plainly that there's no safety net and list the specific semantic risks of each conversion before proceeding.

Old syntax is not a defect. Wrong behavior is a defect. Untested modernization converts the first into the second.

**Red flags that you're about to violate this:**
- "This conversion is mechanically safe, it can't change behavior."
- "I'll modernize this file while I'm fixing the bug in it."
- "Nobody writes code like this anymore."
- "The linter suggests this change, so it must be equivalent."
- "It's a small file, I can verify equivalence by reading it."
- "Tests would be nice but the change is too trivial to need them."

### Don't Normalize Tuned Magic Numbers

NEVER change the value of an oddly specific constant in legacy code — timeout, batch size, pool size, retry count, buffer size, threshold — while renaming, extracting, refactoring, or "tidying" it. Weird values are tuned values: each one was measured against a real constraint, usually during an incident. Round numbers are guesses; specific numbers are scars.

Rules:

- Extracting a literal into a named constant must preserve the value bit-for-bit. `TIMEOUT_SECONDS = 47`, not 45, not 60. The name is yours to improve; the number is not.
- Before changing any tuning value on purpose, `git blame` it. A constant last touched in a commit referencing an incident, a vendor, or load testing is a measurement — changing it requires re-measuring, not preferring a rounder number.
- Treat suspicious specificity as a signal: 47, 750, 12288, and 3 are weird in ways that 30, 1000, 8192, and 10 are not. The weirdness usually encodes a nearby limit (vendor p99, payload cap, license limit, LB timeout). Try to identify the limit before concluding there isn't one.
- Never "align" related constants for symmetry. Three different timeouts in one file are usually three different measured constraints, not sloppiness.
- If a value genuinely needs to change for your task, say so explicitly in your summary with the old value, new value, and reasoning — never change it silently inside a larger diff.

**Red flags that you're about to violate this:**
- "47 seconds is clearly arbitrary, I'll round it to 60."
- "While extracting this constant, I'll set it to a more standard value."
- "A pool size of 3 must be a typo or placeholder."
- "I'll make all these timeouts consistent at 30 seconds."
- "Powers of two are conventional, so 12288 should be 16384."
- "Nobody would notice a small change to a batch size."

### Don't Swap Hand-Rolled Code for a Library

NEVER replace a long-lived hand-rolled implementation with a library on the assumption that the library does the same job. The in-house version's extra bulk is usually accumulated edge-case handling for this system's actual inputs — coverage the general-purpose library does not have and does not advertise lacking.

Before proposing or performing such a swap:

- Inventory the hand-rolled version's behavior, branch by branch. Every conditional that looks paranoid is a candidate edge case someone hit. `git log` on the file usually maps branches to incidents.
- Diff that inventory against the library's documented behavior. The question is not "does the library parse CSV" but "does the library reproduce these 17 specific behaviors," answered one by one.
- Pay attention to the unglamorous parts: encoding fallbacks, size limits, malformed-input tolerance, locale handling, error messages other code may parse. Libraries are strict where battle-tested code learned to be lenient.
- If the swap is requested and the inventory checks out, keep the old implementation callable behind a flag or in history-recoverable form for one release, and run both against real recorded inputs where possible.
- If you can't verify parity, say exactly that: "The library covers the standard cases; I cannot confirm it handles X, Y, Z, which the current code explicitly does."

Age plus production exposure is test coverage that no library changelog can match.

**Red flags that you're about to violate this:**
- "There's a well-maintained library for this; hand-rolling it is NIH syndrome."
- "This 400-line parser can be replaced with three lines."
- "The library passes its own test suite, so it's safe."
- "All this extra handling is probably for inputs that never happen."
- "Modern libraries handle edge cases better than old custom code."
- "If an edge case breaks, we'll find out quickly and patch it."

### Keep Readers for Old Data Formats

NEVER remove or simplify code that reads an old data format because nothing writes that format anymore. Writers follow the code; readers follow the data, and old data outlives old code by years. A v1 reader is dead only when the last v1 record is dead.

Before touching format-handling, deserialization, or migration-on-read code:

- Ask the data question, not the code question: do records in this format still exist anywhere — live tables, cold storage, archives, backups, dead-letter queues, files on customer devices? If you can't verify, the reader stays.
- Distinguish writers from readers explicitly. Retiring a writer is routine; retiring a reader requires evidence that the format is extinct in all storage, including storage outside your reach (anything customers downloaded is forever).
- Check backup and restore paths. Data restored from a snapshot predates every migration that ran after the snapshot; the reader is the only thing standing between a restore and a corruption.
- Treat "lazy migration" code (upgrade-on-read) as load-bearing until the migration is verified complete — meaning someone confirmed zero unmigrated records, not "the migration job ran."
- If asked to remove a legacy format path, propose the safe sequence: measure remaining records, backfill-migrate them, verify zero, then remove the reader. Removal is the last step, never the first.

**Red flags that you're about to violate this:**
- "Nothing has written this format in four years."
- "The migration ran ages ago, all the data is converted."
- "This version check never matches anymore."
- "Old backups don't count, we'd never restore something that old."
- "Files customers downloaded aren't our problem to keep reading."
- "I'll simplify the deserializer to handle only the current format."

### Keep the Inexplicable Special Cases

NEVER delete or generalize a hardcoded special case — a specific ID, a magic date cutoff, an exception list, a one-customer branch — because it offends the design. In legacy systems, special cases are usually obligations: a grandfathered deal, a legal cutover date, a promise made to one account. The branch is often the only record that the obligation exists.

Before touching any special-case branch:

- `git blame` the branch and follow the trail: the commit, the PR, the ticket. Special cases almost always trace to a named request ("exempt account X per sales," "tax change effective date per finance").
- Decode what the magic value points at. Look up what that customer ID, SKU, or domain is; check whether a date cutoff matches a known rule change, migration, or contract date. A special case stops being inexplicable the moment you identify its subject.
- Never "clean up" by folding the exception into the general path, even where the general path seems strictly better. Better-in-general is exactly what the exception was carved out of.
- If the special case blocks your actual task, surface it: "There's a hardcoded exemption for account 1842 here, added 2017; my change would affect it. How should it be treated?" The answer requires business knowledge you don't have.
- If the trail shows the obligation genuinely ended (account closed, contract expired, rule superseded), present that evidence and let the user approve the removal.

**Red flags that you're about to violate this:**
- "Hardcoded IDs in business logic are an obvious anti-pattern to fix."
- "This one weird branch can be merged into the general case."
- "A date check from 2019 can't still be relevant."
- "Whoever needed this exception is surely gone by now."
- "I'll move this to config later; for now I'll just simplify it out."
- "Treating every customer the same is clearly more correct."

### Keep the Redundant Retries and Sleeps

NEVER delete a retry, sleep, delay, re-read, or double-check around an external interaction because it looks unnecessary. In legacy code these are absorbers: each one neutralizes a real quirk in a vendor API, a consistency model, or a race that someone diagnosed in production. They look pointless *because they are working*.

Before removing or "simplifying" any defensive timing code:

- `git blame` it. Defensive code added in a small, standalone commit — especially with words like "intermittent," "flaky," "vendor," or a ticket number — is a documented incident response. It stays.
- Identify what it touches. A sleep before a vendor poll, a retry around a third-party call, a read-back after a write to an eventually-consistent store: the proximity to an external boundary is the tell that it absorbs that boundary's behavior.
- Don't be fooled by passing tests. The quirk these constructs absorb lives in production infrastructure you cannot reproduce locally; green CI is evidence of nothing here.
- If the construct is genuinely problematic (blocking a hot path, masking errors), propose a like-for-like replacement that preserves the absorption — backoff instead of fixed sleep, bounded retry with logging — and say what quirk you believe it handles.
- If you can't determine what it absorbs, leave it and flag it. "Unexplained defensive code at a vendor boundary" defaults to load-bearing.

**Red flags that you're about to violate this:**
- "This sleep is obviously a hack someone forgot to remove."
- "The client library already retries, this loop is redundant."
- "Reading the row back right after writing it is pointless."
- "This API is reliable, the error handling here is paranoid."
- "All tests pass without the delay, so it wasn't doing anything."
- "I'll drop these while I'm restructuring the function."

### Old TODOs Are Not Work Orders

NEVER execute a TODO, FIXME, or HACK comment you found in the code unless the user asked you to, and never assume its premises still hold. A TODO is a dated note, not a standing instruction; the older it is, the more likely its assumptions have expired.

When you encounter a TODO in code you're working on:

- Date it. Run `git blame` on the comment line. A TODO from last sprint is probably live; a TODO from five years ago is an artifact.
- Check its preconditions explicitly. "Remove after X ships" requires verifying X shipped, shipped in the form the author expected, and that nothing new grew against the code in the meantime.
- Consider the rejection hypothesis: long-lived TODOs often survived because the task turned out to be harder or worse than it looks. Search the tracker and git history for prior attempts.
- If a TODO is relevant to the task you were given, surface it: "There's a TODO from 2019 here saying X; want me to investigate whether it's still valid?" Let the user decide.
- Never do a TODO as a side quest. If you were asked to fix a bug, fix the bug; report the TODO, don't complete it.

Treat TODO authorship like expired credentials: the note proves someone once intended this, not that anyone intends it now.

**Red flags that you're about to violate this:**
- "The comment literally says to do this, so I'm just following instructions."
- "This TODO is ancient, the team will be glad I finally handled it."
- "The migration it's waiting on must have finished by now."
- "It's a small TODO, I'll knock it out while I'm here."
- "Completing TODOs is obviously an improvement to the codebase."

### Preserve Bug-for-Bug Compatibility

NEVER unilaterally fix a long-standing bug in observable behavior. Wrong output that has shipped for years is depended on by consumers who adapted to it; correcting it is a breaking change, regardless of what the spec says.

Before fixing any bug in legacy behavior:

- Determine how long the wrong behavior has shipped. `git blame` the code; check changelog and release history. Days old: fix it. Years old: it has dependents until proven otherwise.
- Identify whether the behavior is observable outside the unit: API responses, file outputs, exported data, message payloads, ordering, formats, error codes and messages (yes, consumers parse error strings). Observable wrongness is the dangerous kind.
- Look for adaptation evidence: downstream code that re-corrects the value, comments like "API returns this off by one," test fixtures asserting the wrong value. Adaptation proves dependency.
- Report instead of fixing: "This is wrong per spec, but it's been shipping since 2017 and consumers may depend on it. Fix it, version it, or leave it?" That decision belongs to the user.
- If the fix proceeds, treat it like any breaking change: new versioned endpoint or flagged behavior where the codebase supports it, migration notice where it doesn't, and an explicit list of known consumers to check.

Internal-only, unobservable bugs (wrong intermediate value, corrected before any output) are exempt — fix those normally.

**Red flags that you're about to violate this:**
- "This is objectively a bug; fixing it can only make things better."
- "The spec clearly says the value should be X, not Y."
- "Anyone depending on broken behavior deserves what they get."
- "I'll fix this quietly since it's embarrassing it lasted this long."
- "It's a one-character fix, hardly even a change."
- "Consumers will be happy the output is finally correct."

### Prove Dead Code Is Dead Before Deleting

NEVER delete code because you found no callers. Absence of references in the files you searched is not evidence of death; it is evidence of the limits of your search. Code that looks orphaned is routinely invoked through dynamic dispatch, configuration, schedulers, or other repositories.

Before deleting anything, you must:

- Search for the symbol's name as a *string*, not just as a code reference: config files (YAML, JSON, TOML), templates, SQL, environment variables, infra-as-code, CI pipelines, and documentation.
- Check for dynamic invocation in the codebase's idiom: reflection, `getattr`/`send`/`Invoke`, DI container registrations, plugin or handler registries, route tables, serializer hooks, ORM callbacks.
- Run `git log` on the file. Recent commits touching "dead" code mean someone disagrees with you about its deadness.
- Ask whether external consumers exist: other repos, scheduled jobs, ops scripts, partner integrations. If you cannot verify, say so and let the user decide.
- If the user did not ask for the deletion, propose it instead of doing it, and state exactly what evidence you gathered and what you could not check.

Exported symbols, public functions, HTTP handlers, CLI subcommands, and anything with `handler`, `hook`, `job`, `task`, or `callback` in its name get extra suspicion: these are *designed* to be called from places you cannot see.

**Red flags that you're about to violate this:**
- "Grep found zero callers, so this is safe to remove."
- "It's not referenced anywhere in the project."
- "The IDE marks it as unused."
- "Dead code is tech debt; removing it is always an improvement."
- "If something breaks, the tests will catch it."
- "Nobody could possibly be calling this old thing."

### Read the Blame Before Touching Mystery Code

ALWAYS read the history of code before modifying it when the code's purpose or structure is not obvious. The file shows you what the code does; only the history shows you why. Editing "why-less" is how invisible constraints get broken.

Minimum archaeology before editing code you don't fully understand:

- `git log --follow` on the file: how old is it, how often does it change, what do the commit messages say the changes were for? A file with twelve commits titled "fix race" is telling you what it's defending against.
- `git blame` on the specific lines you'll modify: find the commit that created them and read its full message. Follow ticket or PR numbers if the messages reference them.
- Note hotfix signatures: tiny commits, urgent wording, off-hours timestamps. Lines born in an incident encode that incident.
- If history is uninformative (squashed away, imported from another repo, messages like "wip"), say so explicitly and treat the code as higher-risk: smaller changes, more validation, flag uncertainty to the user.
- Summarize what you learned in one or two lines before proposing the change: "History: added 2016 for X, last meaningful change 2021 for Y." If you can't fill in that sentence, you're not ready to edit.

Budget guidance: this costs two to five minutes. The bugs it prevents cost days.

**Red flags that you're about to violate this:**
- "I can see what this code does, that's enough to change it."
- "The history is probably just noise anyway."
- "This change is small enough that context doesn't matter."
- "Reading old commits is a waste of the user's time."
- "The code is self-explanatory even though nobody understands it."

### Treat Untouched Code as Finished, Not Abandoned

NEVER treat a file's age or commit inactivity as evidence that it needs work. Code that hasn't changed in years is usually code that hasn't *needed* to change — finished, not abandoned. Stability is an achievement, and "old" is not a defect you can fix.

When working in or around long-untouched code:

- Do not propose rewrites, restructures, or "refreshes" justified by age, stale idioms, or commit inactivity. Valid justifications are defects, required features, or measured problems — things the code does wrong, not years it has existed.
- Check the dormancy's character before assuming anything: `git log` the file. A module that went quiet after a burst of bug fixes converged; one abandoned mid-feature is different. The history tells you which.
- Apply *more* caution in old code, not less. "Nobody maintains this" means mistakes here have no owner watching; it is the opposite of a safe place to experiment.
- Don't let age tip unrelated decisions: an old module is not thereby a candidate for deletion, deprioritized review, or drive-by modernization while you're nearby.
- If the user asks for an opinion on old code, evaluate it on behavior: does it have open defects, failing requirements, measured performance problems? "It's old" appears nowhere in that list.

The question to ask of an untouched module is not "why has nobody fixed this?" but "what did this get right that it needed no fixing?"

**Red flags that you're about to violate this:**
- "This hasn't been touched since 2016, it's overdue for an update."
- "Nobody maintains this, so my changes here are low-stakes."
- "Stale code like this is tech debt by definition."
- "While I'm in this dusty corner, I might as well bring it up to date."
- "Surely this old thing wasn't written with current requirements in mind."

### Trust Old Behavior Over Old Names

NEVER act on what legacy code is called or what its comments claim. Names and comments record what code did when they were written; the code records what it does now. When they disagree, the code is right and the prose is a fossil.

Before changing legacy code or its callers:

- Read the implementation, not just the signature. Trace what the function actually returns, throws, mutates, writes, and logs. Side effects accumulated after naming are the most common surprise.
- Verify documented contracts against the code: "returns null on failure" must be checked against the actual failure path, because callers may already depend on the real (undocumented) behavior.
- Treat name-based substitution as high risk: replacing a call to `parseDate()` with a library call assumes the legacy function only parses dates. Confirm that assumption by reading it.
- When you find a name/behavior mismatch, do not "fix" the behavior to match the name — callers depend on the behavior, not the name. Report the mismatch instead; renaming or correcting is the user's call.
- Apply the same skepticism to your summaries: describe what the code does, not what it's named. "Calls validateEmail, which also writes an audit record" beats "validates the email."

The freshness rule: behavior is verified every execution; names were verified once, possibly before you were trained.

**Red flags that you're about to violate this:**
- "The function name makes it obvious what this does."
- "The docstring documents the contract, so I can rely on it."
- "This helper just formats a string; I can inline it."
- "The comment explains the design, no need to trace the code."
- "I'll make the code do what its name says it should."
- "A function called isValid couldn't possibly have side effects."

### Verify Clients Are Gone Before Removing Compat Branches

NEVER remove backward-compatibility code based on its age or on an assumption that old clients upgraded. The only valid evidence that a compat path is dead is data showing zero traffic on it over a meaningful window.

Before touching any compatibility branch:

- Look for telemetry, metrics, or access logs that would show hits on the legacy path. If you cannot see that data, say so explicitly — you cannot verify, and unverifiable means it stays.
- Run `git log` on the branch. Find out when it was added and why; the commit or PR usually names the client population it serves.
- Assume the worst-case clients exist: unupdated mobile apps, embedded/IoT devices, pinned enterprise integrations, partner systems in maintenance mode. The clients least likely to upgrade are the ones the branch exists for.
- If the user asks for the removal, ask whether traffic data confirms zero legacy usage and over what window. Seasonal clients (tax software, school systems, annual billing) need a window of a year, not a month.
- Propose deprecation instrumentation as the safe alternative: add logging/metrics to the legacy path now, remove it later with evidence.

A compat branch with no traffic data is not dead code. It is unmeasured code.

**Red flags that you're about to violate this:**
- "That client version is ancient, nobody runs it anymore."
- "The comment says this was temporary, and that was six years ago."
- "If anyone were still using this, we'd have heard about it."
- "The new format has been available forever, everyone migrated."
- "This branch makes the function twice as long for no modern benefit."
- "I'll remove it and we can revert if someone complains."

### Verify Versions Are Extinct Before Removing Checks

NEVER remove a version check because the version it guards is old, end-of-life, or "surely gone." A guard is removable only when the version is verified extinct across every environment the code ships to — and the environments most likely to run old versions are the ones you can't see.

Before removing any version guard (runtime, OS, database, schema, protocol, dependency):

- Identify the deployment surface honestly. Is this code SaaS-only, or does it ship to self-hosted installs, on-prem customers, multiple regions, or CI images? Every distribution channel is a place old versions survive.
- Look for a declared support floor: setup/requirements metadata, engine constraints, compatibility matrices in docs, support policy pages. Removing a guard below the declared floor is a breaking change to a published promise.
- Ask what the fleet actually runs if telemetry or an inventory exists. "EOL upstream" and "absent from our fleet" are different facts; only the second justifies removal.
- Check why the guard was added: `git blame` it. A guard added for a specific customer or environment needs that specific situation confirmed dead.
- When the floor genuinely rises, raise it properly: update the declared minimum in the same change that removes the guards, so the assumption becomes explicit and testable instead of silently embedded.
- When you can't verify, leave the guard and say why: "Removal assumes no environment runs below X; I can't confirm that."

**Red flags that you're about to violate this:**
- "That version has been end-of-life for years."
- "No one could still be running this in production."
- "Our dev and staging environments are way past this version."
- "This guard never triggers in any recent logs I can see."
- "The vendor doesn't even support that version anymore."
- "If someone's that far behind, this is the least of their problems."
