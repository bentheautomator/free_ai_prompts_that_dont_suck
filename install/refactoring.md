### Carry Comments Through Rewrites

When refactoring, comments, docstrings, and annotations are part of the code. ALWAYS carry them into the restructured version, attached to whatever the relevant logic became. NEVER drop a comment because the code around it changed shape.

Comments are the only record of *why*; deleting one is deleting institutional memory with no test to catch it.

- Before restructuring a region, inventory its comments: docstrings, inline comments, block comments above functions, TODO/FIXME/HACK markers, lint suppressions with explanations, and links to issues, docs, or incidents.
- After restructuring, account for every item: it moved with its logic, was updated to match the new shape, or became genuinely false and was removed deliberately. State removals in your summary with the reason.
- When code moves into a new function, its comments move too. When one function splits into three, the docstring's content gets distributed, not deleted.
- Update stale references in surviving comments ("see `parse_row` above" must track the rename), because a wrong comment is worse than a missing one.
- Warnings are sacred: anything saying "do not", "must", "careful", "ordering matters", or naming an incident or ticket survives every rewrite, verbatim if possible.
- "Good code is self-documenting" applies to comments that restate *what*. Comments that record *why*, external constraints, or history can never be expressed by clearer code, so cleaner code is not a reason to drop them.
- Do not replace specific comments with generic regenerated ones. A docstring listing two real edge cases is worth more than three paragraphs of plausible boilerplate.

**Red flags that you're about to violate this:**

- "The restructured code is clear enough not to need these comments."
- "I'll write a fresh docstring; the old one was out of date anyway."
- "This TODO is ancient; it can't still be relevant."
- "That comment refers to code that doesn't exist in my version."
- "Comments explaining workarounds are clutter once the code is clean."

### Don't Fix Bugs You Find Mid-Refactor

When you discover a bug during a refactor, preserve it exactly and report it. NEVER fix it inside the refactoring change. The refactored code must reproduce the bug faithfully; the bug report goes in your summary as a separate item for the user to decide on.

A silent fix is an unauthorized behavior change, and one secret behavior change destroys the refactor's entire guarantee.

- Preserving a bug means bug-for-bug: same wrong output, same boundary error, same missed case, carried into the new structure deliberately. Add a short comment at the spot if it helps the fix land later (e.g. "preserves existing off-by-one; see notes").
- Report with precision: where the bug is (file, function), what it does wrong, a concrete input demonstrating it, and what the fix would be. A good report makes the fix a five-minute follow-up.
- Resist the "it's a one-character fix" pull hardest. Tiny fixes are the most tempting to fold in and just as much a behavior change as big ones; the size of the edit is not the size of the consequence.
- This is sequencing, not a conflict with correctness. The bug gets fixed *next*, as its own reviewable, testable, revertable change, possibly by you, two minutes from now, with the user's yes.
- If the bug is severe (security hole, data corruption, money mishandled), stop the refactor and escalate immediately instead of burying the finding in a summary. Still don't fix it silently.
- If preserving the bug through the new structure is genuinely impossible (the restructure forces a behavioral choice), pause and ask before proceeding; that refactor and that bug can't be separated, and the user should know.

**Red flags that you're about to violate this:**

- "While I'm here, this comparison is clearly wrong; easy fix."
- "It would be silly to faithfully reproduce a bug."
- "The fix is one character; mentioning it separately is overkill."
- "Surely the refactor should leave the code better than it found it."
- "Nobody could be depending on broken behavior."

### Don't Merge Lookalike Functions

NEVER merge similar-looking functions, branches, or classes just because their text mostly matches. Merge only when they are the same *rule*, meaning they must always change together. Similar code with different reasons to change is not duplication; it's coincidence, and merging it couples things that will need to diverge.

- Before deduplicating, ask: if requirement A changes for one copy, must the other change identically, always? Only "yes" justifies a merge. "They happen to do the same thing today" is "no."
- Domain ownership is the strongest signal: code serving different business concepts (shipping vs billing, trial vs paid, import vs export) stays separate even at 95% textual overlap. Different masters, different functions.
- When you do merge true duplication, the unified function must reproduce BOTH originals exactly. Map every divergent line into the merged version and verify each original call site gets its exact old behavior. Do not "reconcile" small differences; those differences are behavior.
- A merged function that immediately needs a `type` or `mode` parameter and internal branching on it is a confession: you've stapled two functions together, not found one. Prefer keeping both, optionally extracting only the genuinely shared mechanical parts (parsing, formatting) into helpers.
- Two or three copies of something small is an acceptable state. The rule of three exists because the first "duplication" is usually coincidence; wait until the pattern proves itself.
- If you suspect real duplication but can't verify the always-changes-together property, leave the copies and note the suspicion for the user.

**Red flags that you're about to violate this:**

- "These two functions are nearly identical; this is obvious duplication."
- "One parameterized function is cleaner than two copies."
- "I'll unify these and handle the differences with a flag."
- "DRY says this shouldn't exist twice."
- "While merging, I'll also fix the slight inconsistency between them."

### Don't Reorder Side Effects When Extracting

When refactoring, preserve the exact execution order of all side effects: database writes, network calls, queue publishes, file operations, cache updates, log lines, metric emissions, and mutations of shared state. NEVER let regrouping statements into helpers change the sequence in which the outside world sees them.

Tests check return values; almost nothing checks ordering. Reorderings ship green and fail under partial failure, concurrency, or crash, exactly when order mattered.

- Before restructuring, list the side-effecting statements in execution order. After restructuring, trace the new execution order. The two lists must match.
- Grouping by theme (all validation, then all persistence, then all notification) is allowed only if it provably doesn't move any side effect relative to another. When themed grouping would reorder effects, keep the interleaving and group something else.
- Watch the classic landmines: log-before-call vs log-after-call, cache invalidation vs DB commit order, write-then-notify vs notify-then-write, acquiring/releasing in LIFO order, and "send the receipt" relative to "charge the card."
- Moving a side effect across a conditional or loop boundary changes how many times and whether it runs. That's reordering's bigger sibling; same rule.
- Pure computations may be reordered freely if no data dependency objects. The rule is about effects, not arithmetic.
- If an ordering looks wrong or pointless, preserve it and flag it in your summary. Interleavings that survived in production are usually crash-ordering decisions wearing casual clothes.

**Red flags that you're about to violate this:**

- "I'll group all the database operations together for readability."
- "Moving this log line to the end of the function is tidier."
- "The order of these calls doesn't matter; they're independent."
- "Validation should all happen up front, so I'll hoist these checks."
- "The function returns the same result, so behavior is unchanged."

### Don't Simplify Away Edge Cases

NEVER delete a branch, guard, special case, or odd-looking constant during a refactor unless you can state specifically what case it handles and why that case no longer needs handling. "I don't see why this is needed" is a reason to keep it, not remove it.

Strange code in working systems is usually load-bearing: it encodes incidents, vendor quirks, and contractual exceptions that nobody wrote down anywhere else.

- Before removing any conditional, write down (to yourself, then in your summary) the concrete input that takes that branch. If you can't construct one, you don't understand the branch well enough to delete it.
- Treat these as presumed load-bearing: checks for "impossible" values, handling for one specific ID or customer or region, magic sleep durations and retry counts, fallbacks after operations that "can't fail," try/except around "safe" calls, and comparisons that look redundant (`x is None` and `not x` are different checks).
- "The tests still pass without it" is not evidence of deadness. Edge-case handling is exactly the code most likely to be untested, because it was added under fire.
- If you genuinely suspect dead code, don't delete it inside the refactor. Preserve it through the restructure, then list it separately as a removal candidate with your reasoning, and let the user decide.
- Use version control as a witness when available: a branch added in a commit mentioning a bug or incident is handling something real.
- Shorter is not the goal. Same behavior, better shape is the goal.

**Red flags that you're about to violate this:**

- "This condition can never be true."
- "This special case is clearly leftover from some old requirement."
- "Removing these three checks makes the function so much cleaner."
- "No sane input would ever hit this branch."
- "This fallback is paranoid; the call above can't fail."
- "Whoever wrote this was being overly defensive."

### Failing Tests Mean Revert the Refactor

When a test fails after a refactoring change, the refactor is wrong until proven otherwise, never the test. NEVER edit a test's assertions, expectations, or fixtures to make a refactor pass. Fix the refactor to restore the old behavior, or revert it.

During a refactor, "what the test expects" and "correct behavior" are the same thing by definition. Editing the test is deleting the evidence.

- The diagnostic order on any post-refactor failure: (1) assume the refactor changed behavior, (2) find which step changed it, (3) fix that step or revert it, (4) only then, with the refactor green, consider whether the test itself has independent problems.
- A trivial-looking failure (formatting, float precision, ordering, call counts) is still a behavior change. `42.5` vs `"42.50"` means a type changed; one mock call instead of three means side effects changed.
- Legitimate test edits during refactoring are mechanical only: the test imports a renamed symbol, patches a moved module path, or constructs an object whose internal (non-public) shape moved. The *expected behavior* in the assertion never changes.
- If you become convinced the test was wrong all along (it pinned a genuine bug), don't resolve that inside the refactor. Restore the old behavior, get green, and report the suspect test separately with your reasoning.
- Never delete, skip, or mark-as-expected-failure a test to get a refactor through. A skipped test is an edited test with worse manners.
- If the refactor can't pass the existing suite, the deliverable is a revert and an explanation, not a quieter suite.

**Red flags that you're about to violate this:**

- "This test is outdated; it's testing the old implementation."
- "The assertion is too strict; the new output is equivalent."
- "I'll update the expected values to match the new behavior."
- "This test is brittle, it's coupled to incidental details."
- "The test was wrong anyway; the new behavior is what it should have expected."
- "I'll skip this one test for now so the rest of the refactor can land."

### Feature-Flag Branches Are Not Dead Code

NEVER remove a branch gated by a feature flag, environment variable, config value, or runtime setting on the grounds that it appears unused or the gate appears permanently set. Static reading cannot determine runtime reachability; flag values live in systems outside the repo.

- Treat every gate as live: feature-flag checks, `os.environ` reads, config lookups, license/plan tier checks, per-tenant toggles, A/B test branches, and anything named like a kill switch, fallback, or legacy mode.
- "The flag defaults to false" proves nothing; defaults are what remote config and per-environment overrides exist to override. "No code sets this variable" proves nothing; deploy tooling, dashboards, and runbooks set it from outside the repo.
- Kill switches and emergency fallbacks are *designed* to look dead. Their unuse is their readiness. They are the last code in the file you should touch.
- When refactoring code containing flag branches, preserve both sides of every gate through the restructure: same condition, both behaviors intact. Restructure around the flag, not through it.
- Removing a flag and its losing branch (flag retirement) is legitimate, deliberate work, but it is its own task: it requires confirming the flag's state in every environment and with its owner. If you believe a flag is retirable, say so and ask; never retire it as a side effect of cleanup.
- The same applies to the *winning* branch's hardcoding: collapsing `if flag: A else: B` into just `A` is flag retirement too, even though it deletes the "dead" side.

**Red flags that you're about to violate this:**

- "This flag is false everywhere I can see, so the branch is dead."
- "This legacy path can't still be in use."
- "Nothing in the codebase ever enables this, so it's safe to remove."
- "Removing this old A/B branch simplifies the function a lot."
- "The else branch is clearly the abandoned experiment."

### Finish Renames Across Every Call Site

A rename is atomic: NEVER rename a function, class, method, or variable at its definition without updating every reference in the same change. A half-done rename is a broken build at best and a latent runtime crash at worst.

The references you can see in the current file are not all the references.

- Before renaming, search the entire repository for the old name, not just open files. Check: imports and re-exports, call sites, subclass overrides, test files, mocks and patch targets (`patch("module.getUserData")`), fixtures, and type annotations.
- Count the matches before, perform the rename, then search for the old name again. The second search must return zero hits (or only hits you can justify one by one, such as an unrelated symbol that shares the name).
- Watch for dynamic and indirect references that a compiler won't catch: `getattr`, `send`, string-keyed dispatch tables, dependency-injection registrations, and serializer configs that name methods as strings.
- Method renames must include every override in subclasses and every implementation of the same interface, or polymorphic dispatch silently splits in two.
- If the symbol is exported from a package boundary where external callers may exist, do not rename it outright; flag it and ask (see public-API rules).
- If the rename turns out to touch more files than expected, that is not a reason to stop halfway. Either complete it everywhere or revert it entirely. Never leave both names live.

**Red flags that you're about to violate this:**

- "I've updated the callers in this file; that should be all of them."
- "The tests will catch any references I missed."
- "I'll rename the definition now and fix stragglers if something breaks."
- "This is a private helper; nothing else could be using it."
- "The old name only appears in comments now, probably."

### Freeze Public APIs During Internal Cleanup

When refactoring internals, the public surface is frozen. NEVER change anything an external caller could observe: exported function signatures, parameter names in languages with keyword arguments, parameter order, return types, class hierarchies of exported types, HTTP routes and payload shapes, CLI flags, or published constants.

You can verify every internal caller. You cannot verify a single external one. That asymmetry is the whole rule.

- Treat as public: anything exported from the package's entry point, anything documented, any HTTP/gRPC/GraphQL contract, any CLI interface, environment variable names, and anything tests outside the module import directly.
- Keyword-argument languages (Python, Ruby, Kotlin) make parameter *names* part of the contract. Renaming `def search(query=...)` to `def search(q=...)` breaks every caller using `query=`, even though the type checker shrugs.
- Default parameter values on public functions are contract too. Don't "clean up" `timeout=30` to `timeout=None`.
- Refactor freely behind the surface: extract private helpers, restructure internals, rename private members. The public function can become a thin wrapper over a new internal shape; that is the standard move.
- If the cleanup genuinely requires a public change, stop and propose it separately as a breaking change with a deprecation path (new name added, old name delegating, warning emitted). Never just edit the surface.
- Before finishing, diff the public surface explicitly: list every exported symbol and signature before and after. The list must be identical, or you must have flagged the difference.

**Red flags that you're about to violate this:**

- "Reordering these parameters makes the API more consistent."
- "All the callers are in this repo as far as I can tell."
- "I'll rename this keyword argument; the old name was misleading."
- "Returning an iterator is strictly better than returning a list."
- "Nobody passes this argument by name, surely."

### Grep for Strings Before Renaming

Before renaming any symbol, ALWAYS search the entire repository for the name as a plain string, not just as a code reference. Renames break at runtime through references no compiler tracks.

If a name can be spelled in quotes, in config, or in a template, the type checker's approval means nothing.

- Run a repo-wide text search for the old name (and its common case variants: snake_case, camelCase, kebab-case) across ALL file types: YAML/JSON/TOML configs, env files, templates (HTML, Jinja, ERB), SQL, shell scripts, CI pipelines, Dockerfiles, infrastructure code, docs, and READMEs.
- In code, search for the name inside quotes: `getattr`/`setattr`, `send`/`__send__`, `importlib`/dynamic `import()`, mock patch targets, signal/event names, route names, serializer `fields = [...]` lists, admin and form `Meta` declarations, and string-keyed dispatch dicts.
- Framework magic counts: template engines, DI containers, ORM string lookups (`"author__name"`), task-queue task names, and management-command names all resolve symbols from strings at runtime.
- Every string hit gets one of three dispositions, stated explicitly: updated to the new name, confirmed to be an unrelated coincidence, or flagged because it lives outside the repo's control (external cron, saved dashboard, customer config) and the user must decide.
- That third category is a stop sign: if the name is referenced from systems you can't edit, the rename may need an alias or shouldn't happen. Ask.
- After the rename, run the same text search again. Explain any survivor or eliminate it.

**Red flags that you're about to violate this:**

- "My editor's rename-symbol handled all the references."
- "The type checker passes, so the rename is complete."
- "Config files wouldn't reference an internal function name."
- "Templates are presentation; they don't depend on method names."
- "A grep would mostly return false positives, so I'll skip it."

### Keep Defaults Identical When Extracting

When extracting a hardcoded value into a parameter, constant, or config entry, the effective value for all existing callers MUST remain exactly what it was. NEVER normalize a value to something more typical while moving it.

Extraction means relocating a value, not re-deciding it. The original number was usually tuned to something real.

- The default of a new parameter is the literal it replaced, verbatim: `timeout=45` extracts to `timeout: int = 45`, not `= 30`. Same for retries, batch sizes, buffer lengths, ports, limits, sleep durations, and booleans.
- When several call sites used *different* literals, there is no single safe default. Either pass the value explicitly at each site (preserving each one) or stop and ask which should win; never pick the most common and silently change the rest.
- Extracting to config means the config's default (and every environment's config file you control) yields the old value. A new config key whose absence falls back to a different number is a behavior change in disguise.
- Copy values exactly, including units and type: `30` seconds is not `30000` anywhere milliseconds are expected, `0.5` is not `1`, and `None` is not `0`. Recheck every unit boundary you cross.
- Flag defaults are behavior: a hardcoded `verify=True` extracts to `verify: bool = True`. Defaulting it to `False` "for flexibility" is a security change, not a refactor.
- After extracting, diff the effective values: list each call site with its before and after value. Every row must match.

**Red flags that you're about to violate this:**

- "30 seconds is the standard timeout, so that's a sensible default."
- "I'll round this odd value to something cleaner while I'm extracting it."
- "Most callers use 100, so 100 becomes the default."
- "The default doesn't matter much; callers can override it."
- "I'll make the new flag default to false to be safe."

### Keep Log Lines Stable During Refactors

Treat log messages, log levels, structured-log field names, and metric names as a public API during refactoring. NEVER reword, rename, demote, or restructure them in passing. Alerts, dashboards, saved queries, and runbooks match on these exact strings from outside the repo.

A broken alert fails silently, by definition: the symptom of this mistake is the absence of symptoms.

- Keep log message text byte-stable, especially the constant prefix portion that pattern-matching alerts key on. Grammar improvements are not worth a dead pager rule.
- Keep log levels exactly: error stays error, warning stays warning. Levels route to paging policies; a demotion is an unsubscription from incident response.
- Keep structured-log field keys identical (`order_id`, `duration_ms`, `tenant`); saved queries and log-based metrics aggregate on them. Adding new fields is safe; renaming or removing existing ones is not.
- Metric names, label names, and label values are the strictest contract of all: dashboards, SLOs, and alert thresholds reference them by exact string. Never rename a counter "to follow naming conventions" during cleanup.
- When restructuring moves code, make sure its log statements still execute under the same conditions and the same number of times. A log line hoisted out of a retry loop now undercounts; one moved into a loop floods.
- When deleting code, list any log lines and metrics that die with it, so the user can check for dependent alerts.
- If observability naming genuinely needs improving, propose it as dedicated work with a migration (emit both names temporarily, update consumers, retire the old), never as a refactoring side effect.

**Red flags that you're about to violate this:**

- "I'll make this log message clearer while I'm here."
- "Renaming this metric to match the convention is a trivial fix."
- "This is over-logging; warning is the more appropriate level."
- "It's just a log string; nothing programmatic depends on prose."
- "Switching these logs to structured format is a strict improvement."

### Keep Truth Tables When Simplifying Conditionals

When simplifying boolean logic during a refactor, the truth table is the contract: every input that took the true branch before MUST take it after, and likewise for false. NEVER trade an explicit check for a shorter one unless they are equivalent for every value, not just the typical ones.

The inputs that differ are always the edges: null, undefined, empty string, zero, NaN, empty collections, whitespace.

- Before collapsing a condition, evaluate both versions against the edge inputs explicitly: `null`/`None`, `undefined`, `""`, `0`, `0.0`, `NaN`, `[]`, `{}`, `false`. Any divergence means the "simplification" is a behavior change.
- Truthiness shortcuts are language-specific: `if (x)` excludes `""` and `0` in JavaScript and Python but means something else entirely in Ruby, where `0` and `""` are truthy. Never apply one language's idiom to another's semantics.
- `x == null` vs `x === null` in JavaScript, `is None` vs `== None` vs `not x` in Python: these are different predicates, not style variants. Preserve the original predicate.
- Applying De Morgan's laws, distributing negations, or reordering `&&`/`||` chains must account for short-circuiting: if any operand has a side effect or can throw (`x.length` when `x` is null), reordering changes behavior.
- Replacing if/else chains with lookup tables, `switch`, or pattern matching must reproduce the original's fall-through, default, and evaluation-order semantics exactly.
- Combining nested ifs into one condition flattens which checks guard which: `if a: if b:` evaluates `b` only when `a` holds. `if a and b:` matches only if evaluating `b` is safe and effect-free when `a` is false.
- When the original logic is convoluted, restructure for readability while keeping the predicate identical, or state the truth-table change you're proposing and ask.

**Red flags that you're about to violate this:**

- "These two conditions are logically equivalent."
- "A truthiness check is idiomatic here."
- "Strict equality is always safer, so I'll upgrade this `==`."
- "I'll just distribute this negation to flatten the logic."
- "No real input would be the empty string anyway."

### Migrate Callers Before Deleting the Old Path

When replacing an implementation that has multiple callers, NEVER delete the old one in the same change that introduces the new one. The sequence is: add the new path, migrate callers to it incrementally, then delete the old path once nothing references it.

A cut-over diff has no fallback; if one caller was migrated wrong, the working version it could fall back to is already gone.

- Step 1, add: introduce the new function/class alongside the old. Both exist; nothing is broken; this step is trivially safe.
- Step 2, migrate: move callers to the new path in reviewable groups, running tests after each group. Where practical, make the old path delegate to the new one so behavior converges early.
- Step 3, delete: only after a repo-wide search shows zero remaining references to the old path, remove it, as its own small change.
- The temporary duplication between steps 1 and 3 is correct, not a smell. Mark the old path deprecated (comment or annotation) so its pending death is visible, but do not let "two implementations exist" pressure you into collapsing the steps.
- If you're interrupted mid-migration, the codebase still works at every point. That property is the entire reason for the sequence; protect it.
- For two or three trivially mechanical call sites, a single-step swap can be acceptable, but say you're doing it and why the risk is contained.
- The deletion step is mandatory eventually. Parallel paths are scaffolding, not a destination; finish step 3 or hand the user a clear list of what remains.

**Red flags that you're about to violate this:**

- "I'll replace the function and update all twelve callers in one go."
- "Keeping both versions around temporarily is duplicate code."
- "It's cleaner to do the swap atomically."
- "The migration is straightforward, so the intermediate steps are overhead."
- "I'll delete the old one now and fix any callers that break."

### Move Code Verbatim, Then Modify

Moving code and changing code are two different steps. ALWAYS move first, verbatim, and verify; modify afterward, in place, as a separate change. NEVER rewrite code "in flight" between its old location and its new one.

A verbatim move is verifiable by inspection: deleted lines equal added lines. A move-with-makeover is verifiable by nothing.

- Step 1, move: cut the code and paste it into its new location byte-for-byte: same names, same structure, same comments, same formatting, even the parts you intend to change next. The only permitted edits are the mechanical ones the new location forces: import paths, module-qualified references, visibility keywords.
- Verify the move: the code compiles, tests pass, and the deleted block and added block are textually identical apart from those forced mechanical edits, which you can enumerate.
- Step 2, modify: now improve the code in its new home (rename, restructure, restyle to match the module) as its own change with its own focused diff.
- This ordering also keeps history useful: many tools track verbatim moves and preserve blame across them; a rewritten move severs the line-level history at exactly the moment the code is hardest to recognize.
- The same discipline applies in miniature to moving a function within a file, lifting a block into a helper, or hoisting code between layers: relocate exactly, confirm, then change.
- If verbatim arrival truly cannot compile in the new location (name collisions, circular imports), make the minimum forced adaptation, and list each forced edit explicitly so the reviewer can subtract them from the diff.

**Red flags that you're about to violate this:**

- "While moving this, I'll adapt it to the new module's conventions."
- "No point pasting it as-is when I already know what needs fixing."
- "I'll rename it during the move; it's one less diff."
- "Moving it verbatim would leave the new file temporarily inconsistent."
- "The cleanup is small enough to fold into the relocation."

### Never Mix Refactoring With Feature Work

NEVER combine structural refactoring and behavior changes (features, bug fixes) in the same change. One change does one or the other, never both.

Mixed diffs cannot be reviewed (no way to tell moved lines from changed lines) and cannot be reverted (undoing the bug undoes the cleanup).

- If implementing a feature requires restructuring first, do it as two sequential changes: first a pure refactor that changes no behavior, then a feature change against the cleaned-up code. Say explicitly which phase you're in.
- Refactor-first is the normal order: "make the change easy, then make the easy change."
- While doing feature work, do not rename, reformat, extract, or reorganize anything beyond the minimum the feature requires. Note the cleanup you wanted and propose it as a follow-up instead.
- While doing refactor work, do not add parameters "we'll need later," new options, new validation, or any capability that didn't exist before.
- If asked to do both in one request ("clean this up and add X"), still deliver them as two separately reviewable steps, refactor first, and label each.
- Each phase must leave the code in a working state: compiling, tests green.

**Red flags that you're about to violate this:**

- "Since I'm already editing this function for the feature, I'll tidy it up too."
- "These renames are trivial; they won't make the diff harder to read."
- "It's more efficient to restructure and add the feature in one pass."
- "The reviewer will appreciate that I cleaned this up along the way."
- "Splitting this into two changes feels like bureaucracy."

### Never Rename Serialized Fields

NEVER rename a field, property, or enum value on any type that is serialized: to JSON or XML APIs, message queues, document databases, caches, config files, cookies, localStorage, or disk. Those names exist in data you do not control, and the rename orphans every byte already written.

The compiler verifies code against code. Nothing verifies code against stored data; that's your job.

- Before renaming any field, check whether its type flows through serialization: `json.dumps`/`JSON.stringify`, ORM/ODM mappings, protobuf/Avro/Thrift definitions, queue publishers, cache writes, API response builders. If yes, the in-data name is frozen.
- The safe pattern is rename-with-mapping: change the code-level name and pin the serialized name explicitly (`@JsonProperty("usrId")`, `serde rename`, `Field(alias=...)`, ORM `column_name=`). Code gets cleaner; bytes stay compatible.
- Enum values stored in databases or messages are field names' evil twin: renaming `PENDING_REVIEW` breaks every row holding the old string. Same rule, same mapping fix.
- Don't reorder or renumber fields in positional formats (protobuf tags, tuple-based encodings). Position is name.
- Dict keys used as message or cache schemas count, even with no class in sight. `event["usr_id"]` is a wire contract.
- If a true wire-format migration is wanted, that's a project with dual-read/dual-write phases, not a refactor. Propose it separately; never do it inline.

**Red flags that you're about to violate this:**

- "I'll make these field names consistent with the style guide."
- "The rename is safe; the compiler found every usage."
- "This DTO is internal, it just mirrors the API model."
- "Old messages will have drained from the queue by now."
- "Deserialization is lenient, missing fields just default."

### No Big-Bang Rewrites

NEVER refactor by rewriting a file or module from scratch. ALWAYS decompose the refactor into a sequence of small, independently verifiable transformations, and apply them one at a time.

Wholesale rewrites silently drop edge cases, workarounds, and fixes that took years to accumulate. A pile of small mechanical steps preserves them; a regeneration does not.

- Before touching code, list the planned steps (e.g. "1. extract validation into `validate_order`, 2. replace the three duplicated blocks with calls to it, 3. rename `tmp` to `pending_orders`"). Each step should be a named, recognizable transformation: extract, inline, rename, move.
- Each step must leave the code compiling and the tests passing. If a step can't, it's two steps.
- Prefer the smallest diff that achieves each step. If your diff for one step exceeds roughly 50 changed lines, stop and split it.
- If the code is genuinely beyond incremental repair, say so and ask whether the user wants a rewrite. A rewrite is a different task with different risks, and it requires explicit sign-off. Never silently upgrade "refactor" into "rewrite."
- After each step, re-read the diff and confirm no behavior changed: same inputs, same outputs, same side effects, same errors.

**Red flags that you're about to violate this:**

- "Honestly, it's easier to rewrite this file from scratch."
- "The structure is so tangled that incremental changes won't help."
- "I'll rewrite it carefully and keep all the behavior, basically."
- "Most of this code is doing the same thing anyway."
- "A clean-slate version will be much easier to review."
- "I'll just restructure everything in one pass to save time."

**Output checkpoint:** Before submitting a refactor, confirm you can name each transformation you applied. If the honest answer is "I rewrote it," start over.

### No Library Swaps Disguised as Refactors

NEVER replace a library, framework utility, or dependency with a different one as part of a refactor. Restructuring code means reshaping it around the dependencies it already has. Swapping a dependency is a migration, a separate project with its own verification, and it requires the user's explicit go-ahead.

"Equivalent" libraries are equivalent on the happy path and divergent at the edges: parsing leniency, null handling, timezone behavior, retry semantics, thrown vs returned errors.

- Keep every existing import doing its existing job. Refactor the code around `moment`, `lodash`, `requests`, or whatever the file already uses, even if you consider the library outdated, deprecated, or unfashionable.
- "Replace with native equivalents" is a swap too: hand-rolled replacements for library calls (`_.get`, `_.cloneDeep`, `moment().format`) must reproduce edge-case behavior the library spent years accumulating, which a fresh five-liner does not.
- Do not add new dependencies during a refactor either; a refactor's dependency footprint is identical before and after, in both directions.
- Do not bump dependency versions as part of cleanup. Version bumps change behavior on someone else's schedule and belong in their own change.
- If a dependency genuinely deserves replacing (deprecated, unmaintained, security advisories), say so in your summary as a recommendation, with the specific evidence, and let the user schedule the migration. A real migration gets parity tests for the edge behaviors; a smuggled one gets incidents.
- Exception: if the user explicitly asked for the swap, it's the task, not a refactor; do it as a dedicated change with before/after behavior checks on the call sites that exercise edge cases.

**Red flags that you're about to violate this:**

- "This library is deprecated; I'll migrate to the modern one while refactoring."
- "Native array methods can replace all these lodash calls."
- "The newer client has a cleaner API, so the refactored code should use it."
- "It's a drop-in replacement, the APIs are nearly identical."
- "I'll also bump this dependency since I'm touching the file."

### No Refactoring Without a Test Net

NEVER refactor code that has no test coverage of the behavior you're about to restructure. Without tests, "behavior preserved" is an unverifiable claim, and unverifiable claims about refactors are how production breaks.

- Before any refactor, identify the tests that exercise the target code and run them. They are your before/after oracle.
- If no tests cover it, STOP. Tell the user, and offer to write characterization tests first: tests that capture what the code *currently does*, including odd or apparently wrong outputs. Pin current behavior; do not pin your opinion of correct behavior.
- Characterization tests should cover the inputs that matter: typical cases, boundary values, empty/null inputs, and any branch the refactor will restructure. They don't need to be exhaustive, but every branch you intend to reshape needs at least one pin.
- Run the new tests against the *unmodified* code first and confirm they pass. A characterization test that fails on the original code is pinning the wrong thing.
- Only then refactor, and run the suite after each step.
- If the user explicitly declines tests and orders the refactor anyway, proceed in the smallest possible steps, state in your summary that the refactor is unverified, and list the behaviors most at risk.

**Red flags that you're about to violate this:**

- "The change is simple enough that tests aren't really necessary."
- "I can verify equivalence by reading both versions carefully."
- "Writing tests first would double the size of this task."
- "The type checker passing is effectively a test."
- "I'll refactor now and we can add tests later."

### One Module Per Refactoring Pass

Confine each refactoring pass to a single module (one package, one directory, one service). NEVER restructure multiple modules in the same change, even when they share the same smell.

A multi-module refactor has no seams: it can't be reviewed, bisected, or reverted in parts, and a failure anywhere implicates everywhere.

- Pick the target module before starting and name it. Every edited file should live inside it.
- Edits outside the target are allowed only when mechanically forced by the refactor (a caller in another module must follow a changed internal interface) and must be the minimum such edit, not an opportunity to clean that module up too.
- When you spot the same problem in a second module, do not fix it there. Add it to a list and present the list at the end: "the same duplication exists in payments and shipping; want me to do those next, separately?"
- Shared code (utils, common, core) is its own module and the highest-risk target, because everything depends on it. Refactor it alone, in its own pass, never as a side effect of refactoring a consumer.
- Sequence multi-module work as separate passes with verification between them: finish module A, run the tests, get it reviewed or committed, then start module B.
- If a refactor cannot be expressed within one module plus mechanical caller updates, it is an architectural change, not a refactor; stop and say so.

**Red flags that you're about to violate this:**

- "The payments module has the exact same pattern; I'll fix it while I'm at it."
- "It's more consistent to apply this change everywhere at once."
- "These modules are so intertwined that I have to do them together."
- "I'll just quickly align the utils module with the new structure too."
- "Doing them one at a time means three reviews instead of one."

### ORM Renames Require Migrations

NEVER rename an ORM model attribute, model class, or table mapping as a pure code change. Every mapped name is bound to a database object; renaming the code side requires either an explicit column mapping or a deliberate, rename-aware migration, chosen and stated up front.

- The safest cleanup is mapping, not migration: rename the attribute in code and pin the existing column name explicitly (`db_column="cust_nm"`, `@Column(name=...)`, `field :name, as: ...`). Code gets readable; the schema and all data stay untouched.
- If an actual schema rename is wanted, write the migration as a RENAME operation (`RenameField`, `rename_column`, `ALTER TABLE ... RENAME COLUMN`). Never accept an autogenerated migration without reading it: several ORMs autogenerate renames as drop-column-plus-add-column, which destroys the data.
- Read every generated migration aloud in your summary: name the operations it contains. "AddField + RemoveField" in response to a rename is the alarm, not the answer.
- Renames also break the string surfaces: `filter`/`order_by` arguments, `values()`/`only()` lists, serializer `fields`, admin `list_display`, raw SQL, index and constraint definitions, and any report or ETL query in the repo. Search for the old name as a string and fix or flag every hit.
- Table-name and model-class renames carry the same rules plus foreign-key and migration-history implications; treat them as schema projects, not refactors.
- If other services or analysts query this database directly, the column name is a shared contract; flag the rename to the user instead of performing it.

**Red flags that you're about to violate this:**

- "I'll rename the field and regenerate the migration; the ORM handles it."
- "The autogenerated migration looks standard, so I'll include it."
- "It's just an attribute rename; the database layer is abstracted away."
- "Nothing else queries this table directly, most likely."
- "The old column name was inconsistent with our conventions, so this is a cleanup."

### Preserve Concurrency Semantics

When refactoring, the concurrency behavior of the code is part of its behavior. NEVER change what runs sequentially vs in parallel, what is sync vs async, or what is protected by which lock, unless that change is the explicitly requested task.

Sequentiality, locks, and sync boundaries usually encode external constraints (rate limits, ordering requirements, deadlock history) that are invisible in the code itself.

- A sequential loop over I/O stays sequential. Do not introduce `Promise.all`, `asyncio.gather`, thread pools, or batch parallelism as an "improvement"; the loop may be the rate limiter. Propose parallelization separately if you think it's safe.
- Conversely, do not serialize existing parallelism; fan-out is often load-bearing for latency.
- Locks, mutexes, semaphores, and synchronized blocks survive restructuring with identical scope: the same statements guarded, acquired and released in the same order. When extraction splits a critical section, decide explicitly where the lock now lives and verify every formerly guarded statement still is.
- Do not convert sync functions to async or async to sync during cleanup. The color of a function is a contract with every caller; changing it ripples through the whole stack and changes scheduling behavior even when it compiles.
- Preserve what's awaited and when: moving an `await` earlier or later, or dropping a fire-and-forget, reorders observable work.
- Keep thread/task-local state, queue sizes, worker counts, and executor choices identical; they're tuning, not style.
- If the concurrency structure looks wasteful or wrong, finish the shape-preserving refactor and raise it as a separate observation.

**Red flags that you're about to violate this:**

- "These calls are independent, so I'll run them in parallel."
- "Making this async matches the rest of the codebase."
- "The lock can move inside the helper; it's the same thing."
- "Sequential awaits in a loop are a classic performance bug."
- "I'll modernize this to use the concurrent executor while restructuring."

### Preserve Error Handling When Restructuring

When refactoring, the failure paths must survive exactly: every try/catch/finally, retry loop, timeout, fallback, rollback, and resource cleanup. NEVER restructure the happy path and rebuild error handling from approximation.

Error handling encodes the failures that actually happened. It is invisible in normal operation, which makes it the easiest behavior to lose and the costliest.

- Before restructuring, list the error-handling constructs in the target code: exception handlers and exactly which statements each guards, retry/backoff logic and its parameters, timeouts, `finally`/`defer`/context-manager cleanup, error logging, and fallback values.
- After restructuring, verify each item still exists, still guards the same operations, and triggers under the same conditions.
- Extraction changes guard scope silently. If a `try` wrapped statements A, B, and C, and B moves into a helper, decide explicitly where the handler lives now, and confirm A and C are still covered.
- Preserve handler specificity. Don't widen `except ConnectionError` to `except Exception` or narrow it; both change which failures take the recovery path.
- Preserve what handlers do: re-raise vs swallow, the exact fallback value, whether the original exception is chained, whether the error is logged before propagating.
- Cleanup ordering is behavior. A `finally` that closed the file before releasing the lock keeps doing both, in that order.
- If error handling looks excessive or wrong, keep it identical through the refactor and report your doubts separately. Failure paths are the worst possible place for silent opinions.

**Red flags that you're about to violate this:**

- "The new structure is cleaner without all the nested try blocks."
- "I'll consolidate these three catch blocks into one general handler."
- "This retry logic is overkill for a simple call."
- "The error handling can be simplified since these failures are rare."
- "I've kept equivalent error handling, just organized differently."

### Preserve Exception Types and Error Codes

When refactoring, a function's failure interface is frozen: the same conditions must produce the same exception types, error codes, status codes, and failure styles as before. NEVER change what code throws or returns on failure while changing its shape.

Every throw has catchers you can't see: upstream handlers, global error mappers, client retry logic, monitoring matchers.

- Keep exception types exact. Don't replace `ValueError` with a custom exception, a subclass, or a wrapper; don't consolidate distinct exception types into one "cleaner" hierarchy mid-refactor. `except` clauses upstream match on these names.
- Keep failure style: a function that throws keeps throwing; one that returns `None`/error tuples/Result objects keeps doing that. Converting between styles changes every caller's correctness silently.
- Keep error codes, enum values, and HTTP statuses byte-identical: `INSUFFICIENT_FUNDS` stays `INSUFFICIENT_FUNDS`; the 422 stays 422. Clients branch on these.
- Preserve which condition maps to which error. If empty input raised `ValidationError` and malformed input raised `ParseError`, don't merge them; callers may handle them differently.
- When wrapping or re-raising, preserve the original chaining behavior (`raise ... from e`, `cause`); error-reporting tools and debugging depend on it.
- Exception message text is lower-stakes but not free: anything matching on messages (tests, log alerts, client code that shouldn't but does) breaks. Don't reword messages without a reason, and mention it when you do.
- If the error design is genuinely bad, propose a redesigned failure interface as separate work with a deprecation story; never install it during cleanup.

**Red flags that you're about to violate this:**

- "I'll introduce a proper exception hierarchy while I'm in here."
- "Returning None is cleaner than throwing for a missing record."
- "These three error types are redundant; one will do."
- "400 is the more appropriate status for this case."
- "I'm just making the error handling consistent with the rest of the module."

### Refactor Means Behavior-Preserving

When a task is described as a refactor, the observable behavior of the code MUST be identical before and after: same outputs for the same inputs, same side effects, same errors, same edge-case handling. "Refactor" means changing shape, never meaning.

The temptation is to improve behavior while restructuring, because the old behavior looks wrong. Resist it: callers depend on what the code does, not on what it should do.

- Preserve behavior bug-for-bug. If the old code returns `None` for empty input instead of raising, the new code returns `None` for empty input. Oddness is not permission.
- Preserve the full input domain. Inputs the old code accepted (trailing whitespace, mixed case, legacy formats) must still be accepted, even if accepting them seems sloppy.
- Preserve outputs exactly: same types, same rounding, same ordering where callers could observe it, same `null` vs missing-field distinctions.
- If you believe the current behavior is a bug, finish the behavior-preserving refactor first, then report the suspected bug separately and ask whether to fix it. Never bundle the fix in.
- If a structural change you want is impossible without changing behavior, stop and say exactly which behavior would change and why, and wait for approval.
- Describe your change honestly. If any behavior changed, the change is not a refactor and must not be labeled as one.

**Red flags that you're about to violate this:**

- "While restructuring this, I should also make it handle this case correctly."
- "The old behavior here is clearly a bug, so I'll fix it in passing."
- "No reasonable caller depends on this quirk."
- "Returning an empty list is better than returning None anyway."
- "I'll tighten up the validation since I'm rewriting this function."

### Stop When the Refactor Cascades

Set a blast-radius expectation before starting a refactor, and STOP when reality exceeds it. When a refactor forces changes that force further changes (a second hop of ripple, or a file count well past the estimate), pause and report rather than chasing the cascade to completion.

A cascade is the codebase telling you the change is bigger than its description. Plowing through converts that signal into an unreviewable diff.

- Before starting, state the expected footprint: roughly which files and how many. That estimate is the tripwire, so make it honestly.
- Track hops: hop 1 is the planned change plus directly forced caller updates; hop 2 is when those updates force changes elsewhere. Hop 2 means stop. Forced changes to other modules' interfaces, public types, or test infrastructure are automatic stops.
- Default tripwire when no scope was given: more than 2x the estimated files, or more than ~10 files for a "small" refactor, whichever comes first.
- Stop at a coherent point: revert or finish the current step so the tree is green, then report what cascaded, why, the realistic full footprint, and 2-3 options (proceed at full scope, phase it via a compatibility shim, or pick a narrower refactor that doesn't ripple).
- Compatibility shims are the standard cascade-breaker: keep the old signature as a thin adapter over the new one, ship the refactor without touching distant callers, and migrate them later in their own changes.
- NEVER present a cascaded diff for a small-scoped request without having checked in. "It required more changes than expected" in a final summary means you knew at hop 2 and kept going.

**Red flags that you're about to violate this:**

- "This caller also needs updating, and then just a few more."
- "I'm too deep to stop now; finishing is the fastest way out."
- "Each of these changes is individually necessary, so the total is fine."
- "The user wanted the refactor; the extra forty files come with it."
- "It'll be easier to explain after everything compiles again."

### Verify Green Between Refactoring Steps

Refactor green-to-green: run the relevant tests (or at minimum build/typecheck) after EVERY refactoring step, before starting the next one. NEVER stack a second transformation on top of an unverified first.

A failure after one step indicts that step. A failure after six indicts the afternoon.

- The loop is fixed: apply one transformation, run the checks, confirm green, then proceed. The checkpoint is part of the step, not an optional epilogue.
- Use the fastest sufficient check between steps: the module's test file, the typechecker, the build. Run the broader suite at natural milestones and at the end. Speed objections are answered by choosing a faster check, not by skipping the checkpoint.
- If a checkpoint fails, fix or revert THAT step before doing anything else. Do not continue the plan on a red base, and do not fix the failure by starting the next transformation early ("step 4 will resolve this anyway").
- Red-to-red transitions are the trap: when checks were already failing before you started, record the exact pre-existing failures first, and hold every step to "no new failures" against that baseline.
- Commit or snapshot at green points when the environment allows; a known-good state to retreat to converts a bad step from surgery into an undo.
- If you notice you've made several edits without checking, stop and check now, before any further edits. The discipline recovers; the batch doesn't.

**Red flags that you're about to violate this:**

- "These next three steps are trivial; I'll test after all of them."
- "Running the suite between every step is too slow."
- "I'm confident in this change; checking would be a formality."
- "The code won't compile until step 4 anyway, so checks can wait."
- "I'll do one careful review of everything at the end instead."
