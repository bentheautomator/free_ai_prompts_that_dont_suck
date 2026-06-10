### Adapt Every Line You Copy

When you base new code on an existing block, ALWAYS adapt every line — not just the lines that obviously mention the old context. Copying a pattern is good practice; half-adapting it produces code that's still partially wired to the original.

The lines you'll miss are the ones that don't look like code: strings, labels, keys, scopes. They're also the ones where a leftover does the most damage.

**After copying or modeling on existing code, audit the entire block for context leftovers:**
- Log messages and error messages still describing the original operation
- Cache keys, metric names, event names, queue names, and feature-flag keys still using the original's prefix — leftover cache keys mean serving the wrong data
- Permission scopes, role checks, and rate-limit buckets still referencing the original resource
- Comments explaining the original's logic, including doc comments and parameter descriptions
- Variable names, test descriptions, and fixture data that narrate the old context
- Copied edge-case handling that doesn't apply (or applies differently) to the new context — adaptation includes deleting what doesn't transfer
- Final check: search the new block for the original's key terms (e.g., grep your new export handler for "import"); every hit is either justified or a bug

**Red flags that you're about to violate this:**
- "I'll copy the existing handler and tweak it..."
- "Renamed the function and route — that's the substantive part..."
- "The log messages are close enough..."
- "The middle section is identical boilerplate, no changes needed there..." (boilerplate with the old name in it)
- "I've changed all the references..." (without searching for the old term)
- Presenting cloned code without having grepped it for the source's vocabulary

### Check Internal Signatures Before Calling

NEVER call a project function whose definition you haven't read in this session. The name tells you what it probably does; only the definition tells you what it takes, in what order, and what comes back.

Internal functions are guessed at more confidently than library ones — no docs to check means nothing contradicts the guess. The silent failure is two same-typed parameters in the wrong order: no error, wrong result.

**Before writing a call to any function defined in this codebase:**
- Read the actual definition: parameter names, order, types, defaults, keyword-only/positional rules, and what's optional
- Read the return shape: object vs tuple, raw value vs wrapper, what's `None`/`null` when, whether it throws or returns errors
- Or read an existing call site and mirror it exactly — a working call is a verified signature
- Same-typed adjacent parameters (`(from, to)`, `(width, height)`, `(percent, price)`) deserve a second look: order mistakes here produce wrong answers, not errors
- Async matters too: confirm whether it returns a promise/coroutine you must await — calling an async function like a sync one fails quietly in some languages
- If you change your understanding mid-task ("oh, it takes a payload object"), re-check the *other* calls you already wrote against the corrected signature

**Red flags that you're about to violate this:**
- "Based on the name, this function takes..."
- "It probably returns the user object directly..."
- "The natural argument order would be..."
- "I called it this way earlier in the file..." (was that call verified, or also guessed?)
- "It's our own function, the shape will be obvious..."
- Writing a call to an internal function whose definition you have not had on screen

### Clean Up Now-Unused Symbols

After every edit, ALWAYS check what your change just orphaned — and remove it. An edit that reroutes logic strands the variables, parameters, helpers, and fields that served the old route; deleting them is part of the edit, not optional cleanup.

Every orphan misleads: an unused parameter forces callers to keep supplying it, an unused helper invites future maintenance of dead weight, an unused variable implies state that no longer exists.

**After changing any logic, sweep for what no longer earns its place:**
- Local variables whose value is now never read (including ones still being *assigned* — assignment isn't use)
- Parameters your change made meaningless — remove them *and* update the call sites (and if the language complains about unused args in interfaces/overrides, use its idiom: `_`, `_unused`, per convention)
- Private helpers, methods, and small functions whose only caller your edit just removed or rewrote — then check whether *their* removal orphans anything further down; follow the chain
- Class fields, struct members, and state entries that nothing reads anymore
- Constants and config values that only the removed code consumed
- Scope check before deleting: confirm the symbol is truly unreferenced project-wide, not just in this file — exported names need a real search, not a glance
- Symbols that were already unused before your session: mention them, don't silently delete unrelated code

**Red flags that you're about to violate this:**
- "The function works now; the rest of the file is unchanged..." (unchanged is not the same as still-needed)
- "That variable might still be useful to someone..."
- "Removing the parameter means touching the callers — too invasive..."
- "I'll leave the helper; it's harmless..."
- "The linter would have flagged it if it were a problem..." (parameters and exports usually aren't flagged)
- Finishing an edit without asking "what did my change just make pointless?"

### Delete, Don't Comment Out

When code is no longer needed, ALWAYS delete it. NEVER comment it out as a soft delete. Version control is the archive; the source file is for code that runs.

Commenting out feels safer than deleting. It isn't — it's deferred deletion with interest, paid by every future reader who must figure out why the corpse is there.

**Rules:**
- Replacing logic? Delete the old lines in the same edit. Don't leave them commented above, below, or beside the replacement
- Never write `// keeping this for reference`, `# old version`, `/* previous implementation */`, or commented blocks "in case we need to revert" — reverting is what git is for
- Don't disable code by commenting it out as a way to make something pass; if code shouldn't run, remove it (and its tests, imports, and registrations), or surface the question if removal is in doubt
- The exception is genuinely explanatory dead code: a short snippet whose *presence as a comment* documents a non-obvious decision (e.g., "we tried X; it deadlocks under Y — don't"). Such comments must say *why* they exist, not just *what* they were
- Found existing commented-out corpses adjacent to your edit? Leave them unless asked — your job is to not add new ones, not to bulldoze history uninvited

**Red flags that you're about to violate this:**
- "I'll comment this out in case they want it back..."
- "Keeping the old version visible makes the change easier to review..."
- "I'm not 100% sure this is unused, so I'll comment rather than delete..."
- "I'll leave it commented and let them decide..." (without actually telling them)
- "It's only a few lines, it's not hurting anyone..."
- Writing `//` in front of a line instead of removing it

### Delete the Old Implementation

When you replace code, ALWAYS remove what it replaces — in the same change. A replacement isn't done until the old version is gone: not renamed to `_old`, not suffixed `V2`-and-abandoned, not kept "for reference." Gone.

Leaving both versions creates a codebase that lies. Future readers can't tell which implementation is live, callers split between the two, and bug fixes land in the dead copy.

**When your change supersedes existing code:**
- Find every caller of the old implementation and migrate all of them, then delete the old function, class, or block
- Delete the old version's now-unused imports, exports, registrations, and feature-flag plumbing along with it
- Never name the replacement `New`, `V2`, or `Improved` to dodge the conflict — give it the original's name once the original is deleted
- If some callers genuinely can't migrate yet, say so explicitly and ask whether to keep both temporarily; don't silently leave a fork
- After the edit, search for the old symbol name to confirm zero references remain

**Red flags that you're about to violate this:**
- "I'll keep the old version around in case they want to revert..."
- "Removing it might break something I can't see..."
- "I'll call this one processDataV2 to be safe..."
- "Migrating the other call sites is out of scope for this change..."
- "The old one isn't hurting anything by staying..."
- Finishing a "replace X" task with X still present in the file

### Don't Reformat Untouched Lines

ALWAYS keep your diff to the lines the task requires. NEVER reformat, restyle, reorder, or "improve" code you weren't asked to change. The diff IS the deliverable — a 3-line fix must produce a 3-line diff, not a 300-line one with a fix hidden inside.

Every gratuitous changed line costs review attention, pollutes `git blame`, and creates merge conflicts — and noisy diffs are where unintended behavioral changes hide from review.

**Rules:**
- Edit surgically: change the lines that implement the request, plus only what those changes structurally force (an added import, an adjusted indent level around a new block)
- Never requote strings, reorder keys/imports/members, rewrap lines, rename locals, convert syntax (`function`→arrow, `%`→f-string), or fix unrelated style on lines the task doesn't touch — even if the file's style offends you
- If you regenerate a full file for tooling reasons, reproduce every untouched line *exactly* — byte for byte. Untouched lines that differ are a failure, not a bonus
- Spotted something genuinely worth fixing nearby (a real bug, not a style nit)? Mention it in your summary and offer to fix it separately. Don't fold it in silently
- If a formatter is configured and runs on save/commit in this project, formatting your *touched* lines per the config is correct; running it over the whole file when the file wasn't previously formatted is the same noise with extra steps
- Before presenting your change, look at the diff: can you justify every changed line by pointing at the request? Lines you can't justify get reverted

**Red flags that you're about to violate this:**
- "While I'm in this file, I'll tidy up..."
- "I standardized the formatting as I went..."
- "These improvements were too small to mention..."
- "I rewrote the file with the fix included..." (and the other 290 lines?)
- "The reviewer will appreciate the cleanup..." (the reviewer must now review it)
- A diff dramatically larger than the change you were asked to make

### Don't Reintroduce Deprecated APIs

NEVER write a pattern or API into a codebase that the codebase has migrated away from. Your training data over-represents the past; this repo lives in its present. The current pattern in the code outranks the common pattern in your memory.

Every reintroduction is regression by addition: it reopens a finished migration, re-pins a library being removed, and plants a fresh example of the old way for others to copy.

**Before using any API, library, or pattern:**
- Check what the codebase currently does for this need — and weight *recent* code most heavily. If new files all use the new ORM API and only old files use the legacy one, the legacy one is off-limits to new code
- Look for explicit migration signals: deprecation comments, lint rules banning specific imports (`no-restricted-imports`), `MIGRATION.md`/ADR notes, a "deprecated" directory, wrapper modules that adapt old to new
- A library being present in the dependency tree is not endorsement — it may be mid-removal. If two libraries that do the same job are both installed, find which one new code uses, and use that
- Same rule for language/framework idioms: class components in a hooks codebase, `var` in a `const`/`let` codebase, callbacks in a promises codebase — match the era the codebase has reached, not the era your training peaked in
- If you're unsure which of two observed patterns is current, ask — one sentence saves a reopened migration
- Heed deprecation warnings your code generates: a new warning from new code is this failure announcing itself

**Red flags that you're about to violate this:**
- "The classic way to do this is..."
- "moment.js handles this nicely..." (is it even the project's date library anymore?)
- "I've seen this pattern in thousands of projects..."
- "Both APIs work, so either is fine..." (one of them is being removed)
- "The old files do it this way..." (and the new files?)
- Writing a pattern you haven't confirmed appears in this codebase's *recent* code

### Finish Renames Everywhere

A rename is not done until the old name returns zero meaningful search hits. NEVER rename a symbol by updating only the references in front of you — a rename is a codebase-wide census, and the references that hide in strings are the ones that break silently.

**When renaming anything:**
- Search the entire repository for the old name *as text*, not just as a code symbol — case-insensitively, and in every file type: source, tests, fixtures, configs, SQL, templates, scripts, CI workflows
- String-form references are the danger zone: event names, dict/map keys, JSON fields, queue and topic names, env var names, CLI flags, `getattr`/reflection lookups, log-parsing patterns. The compiler will not save you here
- Check name *variants*: `userId`, `user_id`, `USER_ID`, `user-id`, and `UserId` are all the same name wearing different casings — a rename must catch every form
- External contracts (API request/response fields, database columns, published event schemas, env vars set in deployment) may be consumed by systems outside this repo — flag these to the user instead of renaming unilaterally; that's a migration, not an edit
- After the rename, run the search again. Every remaining hit of the old name must be deliberate (e.g., a backwards-compatibility shim) and explainable — say what you left and why

**Red flags that you're about to violate this:**
- "I've renamed the function and updated its callers..." (and its strings?)
- "I searched for the symbol and fixed all usages..." (symbol search misses text)
- "The tests will catch any references I missed..."
- "That string just happens to contain the old name, probably unrelated..."
- "The other casing variants are different identifiers..."
- Declaring a rename complete without a final full-text search for the old name

### Fix Every Copy of Duplicated Logic

When you fix a bug, ALWAYS check whether the broken pattern exists elsewhere — and fix every copy in the same change. Codebases contain cloned logic, and a bug born in a copy-paste lives in every descendant of that paste.

A half-fixed duplicate set is worse than unfixed: the corrected copy becomes evidence that the logic is fine, hiding the broken twins from the next investigation.

**After identifying any bug, before declaring it fixed:**
- Search for siblings of the broken code: grep for the distinctive expression itself (the wrong comparison, the off-by-one boundary, the bad regex), for nearby unusual strings, and for the function/variable names involved
- Check structurally parallel locations even when text differs: if the bug is in the weekly report, read the monthly and quarterly ones; if it's in the `create` handler, read `update`; the same hand usually wrote all of them the same way
- Fix every instance you find, in this change — a list of "other places to fix later" is how twins survive
- If the copies should obviously be one function, note that consolidation is warranted and ask — but never let the prospect of a refactor delay fixing all copies *now*; matching fixes first, consolidation as a separate decision
- Report the full count in your summary: "this bug existed in 3 places; fixed all 3" — or "searched for duplicates, found none." Make the search visible either way

**Red flags that you're about to violate this:**
- "Found the bug, fixed it." (singular, no search)
- "The ticket only mentions the weekly report..."
- "The other modules are probably structured differently..." (read them, don't probably them)
- "I'll fix this instance and flag the rest..."
- "Fixing the others is scope creep..." (it's the same bug)
- Closing out a bug fix without having grepped for the broken pattern even once

### Import Types, Don't Redeclare Them

NEVER declare a type, interface, schema, or model for a domain concept that the codebase already defines. Find the canonical definition and import it. A local redeclaration is a fork of the data model that drifts from the original.

Structural typing makes the fork invisible at first — your three-field `User` interoperates with the real twenty-field one — which is exactly why it survives review and bites later.

**Before declaring any type:**
- Search for the concept's name (`User`, `Order`, `Invoice`, plus the codebase's actual domain vocabulary) in type directories, `types/`, `models/`, `schemas/`, `interfaces/`, shared packages, and generated-types output
- Domain concepts (entities, API payloads, config shapes, events) get imported, always — local declaration of these is forbidden even when you only need three of the fields
- Need a subset or variant? Derive it from the canonical type — `Pick<User, 'id' | 'name'>`, `Partial<Order>`, `Omit<...>`, extending the base model — so the link to the source of truth survives
- Types generated from a schema (OpenAPI, GraphQL codegen, Prisma, protobuf) are *especially* off-limits to redeclare: regeneration updates the real ones and leaves your copy behind
- Genuinely local shapes — a one-off props interface, an internal helper's tuple — are fine to declare; the rule is about concepts that exist beyond your file

**Red flags that you're about to violate this:**
- "I'll just define the fields I need right here..."
- "A quick local interface keeps this file self-contained..."
- "Their User type has too much stuff; mine is leaner..."
- "I don't know where their types live, faster to declare it..."
- "It's structurally compatible, so it doesn't matter..."
- Typing `interface User` or `class Order` without having searched for those names first

### Match the Async Style in Use

ALWAYS write asynchronous code in the same idiom the surrounding code uses. Concurrency style is not a preference slot — the file already chose between async/await, promise chains, callbacks, threads, or an event loop, and your addition joins that choice.

The seams between mixed idioms are where errors get lost: unreturned promises inside async functions, rejections that no callback ever sees, coroutines that are never awaited and never run.

**Before writing async code:**
- Look at how the nearest similar code handles it: async/await vs `.then()` vs callbacks (JS); asyncio vs threads vs sync (Python); goroutines/channels vs sync (Go); and match it — including the error idiom that goes with it (`try/catch` around `await`, `.catch()` on chains, error-first callbacks)
- Don't convert existing code's style to enable yours — write yours to fit theirs; if bridging is unavoidable (a callback API in promise-land), use the codebase's established bridge (`promisify`, existing wrapper utilities), not a hand-rolled adapter
- In an async/await file, never bolt `.then()` onto an awaited expression or leave a promise floating unawaited — every promise is awaited, returned, or explicitly handled
- In Python, never call a coroutine without awaiting it, and never start a new event loop (`asyncio.run`) inside code that may already be in one — find how the codebase enters async and use that path
- Respect the codebase's concurrency primitives: if it has a task queue, a worker pool, or a scheduler for background work, use it rather than spawning ad-hoc threads/tasks

**Red flags that you're about to violate this:**
- ".then() reads more cleanly for this short chain..."
- "I'll fire this off without awaiting; we don't need the result..."
- "A quick background thread is simpler than their task queue..."
- "I'll make this one function async; callers can adapt..."
- "Mixing styles here is fine, JavaScript supports both..."
- Writing async code without having looked at how the file's existing async code handles errors

### Match Codebase Naming Conventions

ALWAYS derive names from the codebase's existing conventions, never from your own defaults. Before naming anything — function, variable, file, class, CSS class, database column, event — find three existing examples of the same kind of thing and follow their pattern.

Conventions are a prediction contract: they let people find code by guessing its name and let tools find files by glob. A name in your style instead of theirs breaks the contract one identifier at a time.

**Conventions to detect and match:**
- Verb vocabulary: if the codebase says `fetch`, don't introduce `get`/`load`/`retrieve` for the same concept; if it says `handle`, don't add `on`/`process` variants
- Casing per context: function/variable casing, class casing, constant casing, file naming (`kebab-case.ts` vs `PascalCase.tsx` vs `snake_case.py`) — these often differ by directory; match the local norm
- Affix patterns: `use*` for hooks, `*Service`/`*Repo` suffixes, `is*`/`has*` for booleans, `_test`/`.spec` for tests, `I*`/`*Impl` if (and only if) they're already in use
- Domain vocabulary: if the codebase calls them `accounts`, your new code doesn't call them `users` — synonyms fork the domain language
- Functionally significant names (test file patterns, migration prefixes, route file conventions) are hard requirements: a wrong name there means tools silently skip your file

**Red flags that you're about to violate this:**
- "I'll name this what it would conventionally be called..." (whose convention?)
- "getUser is the standard name for this..."
- "The casing difference is cosmetic..."
- "I'll use the clearer synonym instead of their term..."
- "New file, so I can use better naming here..."
- Naming something without having looked at what its three nearest siblings are named

### Match the Existing Error Handling Style

NEVER introduce an error-handling paradigm the codebase doesn't already use. Before writing any fallible code, find out how this codebase signals failure — then signal failure exactly that way.

Your default (usually throw/try/catch) is a statistical habit, not a decision. The codebase's pattern *was* a decision, and code that breaks it doesn't merely look different — it escapes the error flow: callers expecting Results won't catch your exception, and centralized handlers never see your hand-rolled response.

**Before writing code that can fail:**
- Read 2-3 existing functions that handle similar failures and identify the pattern: exceptions, Result/Either types, error codes, `(value, err)` tuples, callbacks, sentinel values, centralized middleware
- Use that pattern, including its details: the project's custom error classes (not bare `Error`/`Exception`), its error message conventions, its wrapping idiom (`fmt.Errorf("...: %w", err)`, `raise ... from e`)
- Route errors through existing central machinery (error middleware, global handlers, error boundaries) instead of formatting your own responses inline
- Never silently convert between paradigms at a boundary — a Result-returning function that internally swallows exceptions it should propagate, or vice versa — unless the codebase has an established adapter for exactly that
- If the codebase genuinely has no discernible pattern, use the language's idiomatic default and say which one you chose

**Red flags that you're about to violate this:**
- "I'll wrap this in a try/catch to be safe..." (in a Result-type codebase)
- "Throwing is more idiomatic than what they're doing..."
- "I'll just return null on failure here, simpler..."
- "I'll format the error response right in this handler..."
- "A plain Error is fine, no need for their custom classes..."
- Writing a fallible function without having looked at how its siblings fail

### Match Existing Response Shapes

NEVER design a response shape for a new endpoint. The API already has one — find it and conform. Same rule for inputs: request body conventions, query parameter naming, and pagination style are inherited, not chosen per endpoint.

Clients consume this API generically through shared unwrappers and error interceptors. An endpoint with its own shape breaks every one of those, and turns uniform client code into per-endpoint special cases.

**Before writing any new endpoint or handler:**
- Read 2-3 existing endpoints — ideally the most recently written ones — and extract the contract: envelope structure, error format, status code usage, pagination scheme, field casing (camelCase vs snake_case), timestamp format, null vs absent-field conventions
- Reuse the existing serializers, response builders, presenter classes, or schema types rather than constructing response dicts/objects inline — if a `make_response()` helper or base serializer exists, that's the API contract in code form
- Your framework's default error format is not the API's error format unless the codebase demonstrably uses it — check how existing handlers return errors before letting the framework answer for you
- Errors conform too: same envelope, same code/message structure, same status-code conventions as the rest of the API
- If the requested feature genuinely can't fit the existing shape, say so and ask — don't quietly ship the exception

**Red flags that you're about to violate this:**
- "I'll return the list directly, simple and clean..."
- "The framework's standard error response is fine here..."
- "I'll add page/limit params for pagination..." (in a cursor-paginated API)
- "Building the response inline is more readable than their serializer machinery..."
- "snake_case is more standard for JSON..." (in a camelCase API)
- Writing a handler without having read what any sibling endpoint returns

### Match the File's Formatting Style

ALWAYS write new code in the formatting style of the file it's going into — not the style you'd choose. You have formatting preferences from training averages; the file has formatting facts. Facts win.

**Before writing into any file, observe and match:**
- Indentation: spaces vs tabs, and the width — copy it exactly; in Python and YAML a mismatch is a syntax or structure error, not a style nit
- Quotes: single vs double vs backticks, and when each is used
- Semicolons (in languages where they're optional): present or absent, consistently
- Brace and spacing style: same-line vs next-line braces, spaces inside parens/brackets, trailing commas in multiline literals
- Line-length discipline: if the file wraps at ~80, don't write 140-character lines
- Blank-line rhythm between functions and logical sections

**Also:**
- If the project has a formatter config (`.prettierrc`, `.editorconfig`, `rustfmt.toml`, `pyproject.toml [tool.black]`), that config is the answer — follow it, and run the formatter on touched files if it's available
- Never "fix" the file's existing style to match your output; your output matches the file
- If the file is internally inconsistent, match the style of the code immediately surrounding your edit

**Red flags that you're about to violate this:**
- "I'll write this in standard style..."
- "Double quotes are more common, so..."
- "I'll use proper 4-space indentation here..." (in a 2-space file)
- "The formatter will normalize it anyway..." (unverified that one exists)
- "Adding semicolons is harmless..."
- Writing a block without having consciously noted the file's quote, indent, and semicolon choices

### Match the Import Order Convention

ALWAYS insert new imports according to the ordering and grouping convention already present in the file. The import block has structure; find it before you add to it.

Appending to the bottom of the block "because it works" fails lint in enforced projects and rots the convention in unenforced ones.

**When adding an import:**
- Read the existing import block first and identify the scheme: grouping (stdlib / third-party / local), ordering within groups (alphabetical, by path depth), blank-line separators, and style (`import x` vs `from x import y`, default vs named, aliasing patterns)
- Insert the new import into its correct group and position — not at the end of the block, not above the code that uses it
- Match the file's import *style* too: if the file does `from datetime import datetime`, don't add `import datetime`; if it aliases `import numpy as np`, use the established alias
- All imports go at the top of the file in the import block unless the codebase demonstrably uses inline imports for a reason (lazy loading, circularity workarounds) — and then only where it already does
- If the project has an import sorter configured (`isort`, `goimports`, `import/order`, formatter settings), conform to what it would produce; run it on touched files if available

**Red flags that you're about to violate this:**
- "I'll add the import at the end of the list..."
- "I'll import it right here next to where it's used, keeps things local..."
- "The order doesn't matter functionally..."
- "Their grouping looks inconsistent anyway, so anywhere is fine..."
- "The formatter will fix the placement..." (in a project with no formatter)
- Adding an import line without having read the existing block's structure

### Match the Language Version Target

NEVER use language syntax or runtime features newer than what the project targets. The target version is a declared fact — find it before writing anything fancy, and write to it.

You default to the newest dialect you know. The project deploys on what it deploys on, and "nicer syntax" is not a feature on a runtime that throws `SyntaxError` at import time.

**Find the target first:**
- Python: `requires-python`/`python_requires` in `pyproject.toml`/`setup.py`, CI matrix, Dockerfile base image
- JS/TS: `tsconfig.json` `target` and `lib`, `browserslist`, `engines` in `package.json`, Babel config
- Go: the `go` directive in `go.mod` • Java: `--release`/`sourceCompatibility` • Ruby: `required_ruby_version` • C#: `LangVersion`/`TargetFramework`
- If several disagree, honor the oldest one that's actually deployed against

**Then respect it, including the subtle cases:**
- Syntax is only half the rule — built-in APIs and standard-library additions version too (`str.removeprefix` is 3.9+, `Array.at` is ES2022, `zoneinfo` is 3.9+). Transpilers convert syntax, not missing APIs, unless polyfills are configured
- Libraries with declared version support must be written to their *minimum* supported version, not the maintainer's laptop
- Check what the codebase itself uses: if no f-strings appear anywhere, there may be a reason — match the dialect you observe
- If a newer feature would genuinely improve the change, propose the version bump explicitly; don't smuggle it in as syntax

**Red flags that you're about to violate this:**
- "Modern Python/JS handles this elegantly with..."
- "Everyone's on at least version X by now..."
- "The transpiler will take care of it..." (of the API too?)
- "This syntax has been around for a couple of years..."
- "Tests pass locally, so compatibility is fine..." (local runtime ≠ target runtime)
- Using a feature without knowing which version introduced it and which version this project targets

### Never Hand-Edit Generated Files

NEVER hand-edit a file that a tool generates. Generated files are output; the change you want goes into the *input* — the schema, the spec, the manifest, the template — followed by rerunning the generator.

A hand edit to generated output is at best temporary (the next generation erases it) and at worst corrupting (a desynced lockfile breaks installs for the whole team).

**Files that are output, not source:**
- Lockfiles: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `poetry.lock`, `Cargo.lock`, `Gemfile.lock`, `go.sum` — change `package.json`/`pyproject.toml`/etc. and run the package manager
- Codegen output: GraphQL/OpenAPI/protobuf/Prisma generated types and clients — change the schema or spec, rerun the generator
- Build artifacts: `dist/`, `build/`, compiled CSS, bundles — change the source they're built from
- Anything with a `DO NOT EDIT` / `@generated` / `AUTO-GENERATED` header, or matching the repo's documented generated paths — that header is a hard stop, not a suggestion
- Snapshot and fixture files owned by a tool: regenerate via the tool's update command, never by typing the expected output in

**Process:**
- Before editing an unfamiliar file, check the first few lines for a generated header and the path against generator configs
- If you can't run the generator in your environment, make the source change and tell the user exactly which command to run — do NOT simulate the generator by editing its output
- If output and source appear out of sync, report it; don't "fix" the output to match

**Red flags that you're about to violate this:**
- "I'll add the entry to the lockfile directly..."
- "Quicker to fix the generated type than rerun codegen..."
- "I'll update both the schema and the output to match..." (the generator updates the output)
- "The DO NOT EDIT header is just boilerplate..."
- "I'll hand-write what the generator would have produced..."
- Editing a file whose first line you haven't read

### No Hallucinated Library Methods

NEVER call a library method you haven't verified exists. Plausible is not the same as real.

You generate API calls by pattern-matching against what a library's interface "should" look like. Library authors did not consult your training data. Methods get blended across similar libraries (`requests` vs `httpx`, `lodash` vs `ramda`, `pandas` vs `polars`), and the resulting call reads perfectly while being completely fictional.

**Before calling any library method, verify it one of these ways:**
- Find an existing call to the same method elsewhere in this codebase
- Check the library's source or type definitions in `node_modules/`, `site-packages/`, `vendor/`, or wherever dependencies live
- Check official documentation for the exact method name and signature
- Run a quick REPL check or `grep` against the installed package

**Specific rules:**
- If you can't verify a method exists, say so and verify before writing the call
- Prefer methods the codebase already uses over methods you "remember"
- Pay extra attention to utility libraries and ORMs — these have the highest hallucination rates because so many near-identical variants exist
- Hallucinated methods in error handlers and rare branches are the most dangerous, because the happy path hides them — verify those calls hardest

**Red flags that you're about to violate this:**
- "This library almost certainly has a method for this..."
- "The conventional name for this would be..."
- "I remember this API from similar libraries..."
- "It follows the same pattern as the other methods, so..."
- "This is such a common operation, there must be a built-in..."
- Writing a method call you've never seen in this codebase or its docs

### No Invented Config Options

NEVER write a configuration key you haven't verified against the tool's actual schema or documentation. Config files are where hallucinations go to hide, because most tools silently ignore unknown keys instead of erroring.

A made-up option doesn't fail loudly. It just does nothing while everyone believes it's working — fake caching settings, fake security flags, fake timeouts.

**Before adding or changing any config option:**
- Verify the exact key name and value type against the tool's documentation, JSON schema, or typed config definitions for the version in use
- Check existing config files in this project for how similar options are spelled and nested — nesting errors (right key, wrong level) are as fatal as wrong keys
- If the tool offers validation (`tsc --showConfig`, `eslint --print-config`, schema-validated YAML, `--check`/`--dry-run` flags), run it after editing
- Never blend option names across similar tools — Jest options into Vitest config, npm fields into pnpm, GitLab CI keys into GitHub Actions
- If you cannot verify a key exists, say so instead of writing your best guess into a file nobody will question

**Red flags that you're about to violate this:**
- "A tool like this would definitely have an option for..."
- "The naming convention suggests the key would be called..."
- "This is how the similar tool spells it, so..."
- "I'll set this to true — that's usually what it's called..."
- "The exact name might differ slightly, but this should work..."
- Writing a config key you've never seen in this project's files or the tool's docs

### No Placeholder Values in Real Code

NEVER fill a value you don't know with a placeholder and present the code as finished. `YOUR_API_KEY`, `example.com`, `<your-bucket-name>`, dummy IDs, and tutorial defaults are holes wearing value-shaped costumes — and the plausible-looking ones don't even announce themselves before misrouting real behavior.

When you don't know a value, that's information to surface, not a blank to pad.

**Rules:**
- Real values you need but don't know (URLs, keys, IDs, emails, bucket names, ports): first look for them — config files, env files (`.env.example` counts), existing code that talks to the same service, deployment manifests. Most "unknown" values are written down somewhere in the repo
- If genuinely absent: wire the code to read from configuration/environment (matching how the codebase already does this), and explicitly tell the user which variable they must set — in your summary, not just a comment
- If the code can't be structured that way, STOP and ask for the value rather than shipping filler
- Never invent plausible-looking concrete values: fake UUIDs, made-up account IDs, guessed ports, `test@test.com` defaults. A value that looks real is worse than one that screams placeholder
- Never use a real-looking domain you don't control (`example.com` is reserved and safe in docs; in running code it's still a wrong value)
- `.env.example`, documentation, and test fixtures are legitimate placeholder territory — this rule governs code that's meant to execute for real

**Red flags that you're about to violate this:**
- "They'll replace this with their actual key..."
- "I'll use example.com as a stand-in..."
- "A placeholder makes it obvious what goes here..." (obvious to whom, when?)
- "I'll default it to something sensible for now..."
- "Any UUID works for the initial version..."
- Typing angle brackets, `YOUR_`, or `_HERE` inside a file that's supposed to run

### No TODO Placeholders in Delivered Code

NEVER substitute a TODO comment or stub for code you were asked to write. If the task includes it, implement it; if you can't implement it, say so out loud — don't bury the gap in a comment and present the work as done.

A TODO you write is an unauthorized IOU. The user asked for working code and got a marker where working code should be, with no flag in your summary to warn them.

**Rules:**
- Implement the requested behavior fully, including the fiddly parts (error paths, pagination, edge cases that are in scope) — fiddly is not the same as out of scope
- If something genuinely can't be implemented now (missing credentials, undecided requirements, blocked dependency), state it explicitly in your response and let the user decide; their explicit approval is what turns a gap into a legitimate TODO
- Never write `TODO`, `FIXME`, `XXX`, `not implemented`, or stub bodies (`pass`, `return null  // temporary`, `throw new Error("TODO")`) as a way to move past a hard sub-problem
- Never write a TODO that describes a missing safety behavior (`// TODO: validate`, `// TODO: handle failure`) while the code proceeds without it — that's an unhandled case, not a note
- Before finishing, scan your own diff for TODO/FIXME/stub markers; every one you find must either be implemented or surfaced in your summary

**Red flags that you're about to violate this:**
- "I'll mark this part as TODO and move on..."
- "The core logic is done; the edge cases can be follow-ups..."
- "This needs more context, so I'll stub it for now..." (without telling anyone)
- "Handling that case properly would make this change bigger..."
- "A TODO here makes the gap visible..." (visible in a place no one reads)
- Writing a comment that describes work instead of doing the work

### Obey the Lint Config

ALWAYS write code that passes the project's configured linters and static checks — and when it doesn't, fix the code, NEVER the rule. Suppression comments and config edits are policy overrides, not fixes, and they're not yours to make.

The lint config is the team's definition of acceptable code, written down. Code that violates it isn't done; code that suppresses it is worse than not done.

**Rules:**
- At the start of work in a repo, check what's configured: `.eslintrc*`, `ruff.toml`/`pyproject.toml`, `.golangci.yml`, `rubocop.yml`, `clippy` settings, `tsconfig` strictness flags, and note the rules that will bite (banned types, complexity limits, required error handling, naming patterns)
- Write to those rules from the first line — don't generate your default style and patch it after
- If lint commands are runnable in your environment, run them on the files you touched before declaring the work complete
- On a violation, the fix is conforming code. `eslint-disable`, `noqa`, `type: ignore`, `#[allow(...)]`, `@ts-ignore`, and `@SuppressWarnings` require explicit user approval, case by case — and so does ANY edit to a lint or compiler config file
- The narrow exception: codebases that use sanctioned, documented suppressions for known patterns (e.g., a commented `noqa` idiom). Match those exactly where they already apply; never extend the practice to new rules
- If a rule seems genuinely wrong for what you've been asked to build, say so and ask — the user can overrule their linter; you can't

**Red flags that you're about to violate this:**
- "I'll add a quick eslint-disable for this line..."
- "This rule is overly strict for this case..."
- "A type: ignore here keeps things moving..."
- "I'll loosen this one setting in the config..."
- "The linter is wrong about this pattern..."
- Reaching for a suppression comment within seconds of seeing the lint error

### Only Import Installed Packages

NEVER import a package that isn't in this project's declared dependencies. Check the manifest — `package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile` — before writing any third-party import.

This rule has teeth for two reasons. First, an uninstalled-but-real package is an unauthorized dependency decision: supply-chain surface, licensing, and maintenance burden added as a side effect of a code edit. Second, a package you *invented* is now a security incident waiting to happen — attackers register the plausible-sounding names AI models consistently hallucinate (slopsquatting), so "just install the missing package" can mean installing malware.

**Rules:**
- Before any third-party import: confirm the exact package name appears in the dependency manifest. Exact — `psycopg2` vs `psycopg2-binary`, `discord.py` vs `discord`, scoped vs unscoped npm names all differ
- If the functionality needs a package that isn't installed: STOP and say so. Name the package, why it's needed, and let the user decide to add it. Never write the import and let the error prompt an install
- Never instruct the user to `pip install` / `npm install` a package you haven't verified exists on the official registry under that exact name
- Prefer solving with what's already installed or the standard library before proposing any new dependency
- Transitive availability doesn't count: a package being pulled in by another dependency is not a license to import it directly

**Red flags that you're about to violate this:**
- "This is a very common package, it's surely installed..."
- "There's a package for this — I believe it's called..."
- "They can just install it if it's missing..."
- "I've seen this import in countless projects..."
- "The dependency of their dependency includes it, so importing is fine..."
- Writing a third-party import without the manifest open in this session

### Pick the Dominant Style, Never a Third

When a file or module contains competing styles, ALWAYS write new code in one of the existing styles — never introduce a third. Inconsistency is not permission; it's a tiebreak you must resolve, in this priority order:

1. **The project's enforced style** — formatter/linter config, style guide, or a convention clearly followed by the rest of the codebase
2. **The dominant style** — the one used by more of the file, by count
3. **The newer style** — if counts are close, match the most recently added code (check which style the newest functions use); codebases migrate forward, and you shouldn't add to the legacy pile
4. **The style nearest your edit** — if all else ties, match the code your change sits inside

Adding a third style is the only unambiguously wrong move: it reduces the file's signal for every future contributor (human or AI) and accelerates the decay you're reacting to.

**Also:**
- Do not take the inconsistency as an invitation to reformat the file to your preferred style — uninvited mass restyling buries the actual change and is a different failure, not a fix
- If the inconsistency is severe enough to genuinely block clean work, say so and ask whether a cleanup is wanted as a separate change
- This applies beyond formatting: async paradigms, component patterns, state management approaches, test structure within a file

**Red flags that you're about to violate this:**
- "This file is inconsistent anyway, so I'll write it the clean way..."
- "Neither of their approaches is ideal; mine is clearer..."
- "Since there's no convention here, I'll use the modern pattern..." (there are two conventions; pick one)
- "I'll take this opportunity to standardize the file..."
- "My addition is self-contained, its style doesn't need to match..."
- Noticing two styles and feeling freed rather than obligated

### Read Before Edit

NEVER edit a file you haven't read in this session.

**The core problem:** AI models have strong priors about what code "probably looks like." Given a filename and a task description, they'll generate a convincing edit without ever looking at the real file. The edit applies cleanly about 60% of the time. The other 40% is wasted time, broken code, or subtle bugs from mismatched context. Reading first takes five seconds. Fixing a hallucinated edit takes an hour.

**Before modifying any file, you MUST:**
1. Read the file (or the relevant section of it)
2. Understand the existing patterns, naming conventions, and structure
3. Make changes that are consistent with what's already there

**This means:**
- Read the file before writing to it — every time, no exceptions
- If the file is large, read at least the section you're modifying plus surrounding context
- Follow the patterns you see, not the patterns you'd prefer
- Match existing naming conventions, indentation, and code style — even if they're not what you'd choose
- If you're changing a function, read the callers too

**Red flags that you're about to violate this:**
- "Based on the typical structure of this type of file..."
- "This file probably contains..."
- "I'll add the standard boilerplate for..."
- "I know how this framework works, so..."
- "The function signature is probably..."
- Generating an edit without a preceding file read

### Remove Orphaned Imports

ALWAYS reconcile the import block after editing a file. When you remove or rewrite code, the imports that only served that code must leave with it.

Your edits are local; imports are global to the file. Code you delete in line 200 silently orphans a name declared in line 3, and you will not notice unless you look.

**After any edit that removes or replaces code:**
- Re-check every import in the file: is each imported name still referenced below? Remove the ones that aren't
- Removing one name from a multi-name import? Trim just that name (`import { a, b }` → `import { a }`), don't delete bindings that are still used
- Apply the same reconciliation to the mirror case: code you *add* needs its imports added — never reference a name the file doesn't import just because the snippet in your head had it in scope
- Watch for imports kept alive only by side effects (Python module registration, CSS imports, polyfills) — if one looks unused but might be load-bearing, leave it and say so rather than guessing
- If the project has a lint rule or formatter that manages imports, run it on the touched files before declaring the edit complete

**Red flags that you're about to violate this:**
- "The edit is done — the function works now..." (without re-reading the imports)
- "The linter will clean those up eventually..."
- "I only touched the middle of the file, the top is unchanged..." (unchanged is the problem)
- "That import might be used somewhere else in the file, probably..."
- "Removing imports is risky, safer to leave them..."
- Declaring an edit finished without having looked at the import block since your change

### Search Before Writing Helpers

NEVER write a utility function without first searching the codebase for an existing one that does the job. Writing a helper is easy; that's exactly why it's the wrong default.

Every duplicate helper is a future divergence bug. The two copies start identical-ish and drift until two screens disagree about what the same value looks like.

**Before writing any general-purpose function (formatting, parsing, validation, retry, debounce, date math, string manipulation, deep clone, etc.):**
- Search for the obvious names AND their synonyms: `format`/`render`/`display`, `validate`/`check`/`is`, `retry`/`withRetry`/`backoff`
- Look in the conventional homes: `utils/`, `lib/`, `helpers/`, `common/`, `shared/`, `pkg/`, and the module you're editing
- Check whether an installed dependency already provides it before writing it from scratch
- If you find an existing helper that's close but not exact, prefer extending or wrapping it over writing a parallel one — and say what you found
- If you genuinely find nothing, put the new helper where the codebase keeps its utilities, not inline in your feature file

**Red flags that you're about to violate this:**
- "I'll just write a quick helper for this..."
- "It's only five lines, faster to write than to find..."
- "A codebase this size might have one, but inline is simpler..."
- "Their version might not handle my exact case, so I'll make my own..."
- "I'll define it locally to keep this change self-contained..."
- Writing a function whose name you haven't grepped for

### Update All Callers on Signature Change

NEVER change a function's signature — parameters added, removed, reordered, renamed, return shape changed — without finding and updating every call site in the same change. The definition edit is the easy 10%; the callers are the job.

Call sites you haven't seen don't stop existing. In dynamic languages they break silently and detonate at runtime, often inside the error-handling paths that run least.

**When changing any signature:**
- Search the entire codebase for the function name before editing — including dynamic references: decorators, callbacks, event handler registrations, strings used for dispatch, and re-exports
- Update every caller in the same edit session, not "in a follow-up"
- Changed the return type or shape? Then every *consumer* of the return value is a call site too — check destructuring, `.property` access, and truthiness checks on the result
- In dynamically typed code, be extra exhaustive: nothing will catch what you miss
- If there are too many callers to update safely, say so and propose adding a parameter with a default instead — a deliberate compatible change beats an accidental breaking one
- After editing, re-run the search and confirm every remaining reference matches the new signature

**Red flags that you're about to violate this:**
- "I've updated the function and its usage..." (singular)
- "The compiler will catch any call sites I missed..."
- "This function is probably only called from here..."
- "I'll update the other callers if anything breaks..."
- "The new parameter is optional-ish, most callers won't care..."
- Editing a definition without having run a project-wide search for its name first

### Use Existing Constants, Not Literals

NEVER hardcode a value that the codebase already defines as a named constant, enum, or config entry. A literal that duplicates a constant is a bug with a delay timer: it works until the constant changes, then silently doesn't.

**Before writing any literal that carries meaning — timeouts, limits, retry counts, status strings, role names, error codes, URLs, queue names, currency codes, dimensions:**
- Search for the value itself and for likely constant names (`MAX_`, `DEFAULT_`, `_TIMEOUT`, `Status.`, `Role.`, enum files, `constants.*`, `config.*`)
- If the constant exists, import and use it — even when that means adding an import to a file that didn't have one
- If the codebase compares against an enum, compare against the enum member, never its string value
- If the value appears 2+ times in your own new code and no constant exists yet, define one where the codebase keeps them
- Plain structural literals (`0` for an index start, `1` for an increment, `""` for empty-check) are fine — the rule is about values with domain meaning

**Red flags that you're about to violate this:**
- "It's just a 3, I'll inline it..."
- "The string 'shipped' is what the API returns, so comparing directly is fine..."
- "Importing the constants module for one value feels heavy..."
- "I'll match the value they're using elsewhere..." (matching the value instead of referencing the name)
- "This number won't change..."
- Typing a quoted status, role, or event name without checking whether an enum defines it

### Use the Existing Validation Layer

In a codebase that validates through schemas or a validation framework, NEVER hand-write input checks with inline conditionals. Validation goes through the layer — that's where the rules, the error shape, and the type inference live.

A handler with manual if-checks has seceded from the validation system: weaker rules than the shared schemas, error responses the clients can't parse, and logic that never receives updates made to the central definitions.

**Before validating anything:**
- Find the project's validation mechanism: schema libraries (`zod`, `yup`, `joi`, Pydantic, marshmallow, DRF serializers), framework validation (class-validator decorators, Rails validations, FastAPI models), or JSON Schema middleware — look at how the nearest existing endpoint validates its input and do exactly that
- Define new validation as the codebase does: a schema/model/serializer, registered or applied the same way (middleware, decorator, parse call), in the same location the project keeps them
- Reuse existing field-level definitions instead of redefining them — if a shared `emailSchema` or address model exists, compose it; a fresh inline email regex is the validation version of duplicating a helper
- Let validation errors flow through the layer's error handling so responses keep the standard shape — never hand-format your own 400s alongside a system that formats them
- The same applies beyond HTTP: message consumers, form handling, config parsing — wherever the project validates declaratively, declarative is the local law
- Checks the layer genuinely can't express (cross-record uniqueness, permission-dependent rules) go where the codebase puts *those* — find one example before inventing a location

**Red flags that you're about to violate this:**
- "I'll add a few quick checks at the top of the handler..."
- "A schema is overkill for two fields..."
- "I'll just verify the email format with a regex here..."
- "Manual validation is more explicit and readable..."
- "I'll return a 400 with a clear message..." (in whose error shape?)
- Writing `if (!body.field)` in a repo whose handlers all start with a schema parse

### Use the Framework, Not a Handroll

NEVER hand-implement functionality that the project's framework or installed dependencies already provide. Before writing infrastructure-flavored code — pagination, validation, serialization, auth checks, caching, retries, date math, query building, escaping, parsing — check whether the stack already does it.

Your hand-rolled version will be longer, less correct, and permanently owned by this team. The framework's version has had its edge cases beaten out of it by years of other people's incidents.

**Before writing such code:**
- Check what the framework offers: ORMs paginate, validate, and escape; web frameworks parse, route, and handle CORS; standard libraries do more than you assume
- Check the installed dependencies (`package.json`, lockfiles, `requirements.txt`, `go.mod`) — a project with `zod` installed wants schemas, not if-chains; a project with `date-fns` wants `addDays`, not millisecond arithmetic
- Check how the codebase already solves it: if existing endpoints use the framework's paginator, your endpoint does too
- Treat hand-rolling as the option of last resort, taken only when the stack genuinely lacks the facility — and say so when you do, so the choice is visible
- Security-adjacent handrolls (escaping, sanitization, crypto, query construction) are forbidden outright when any library alternative exists

**Red flags that you're about to violate this:**
- "This is simple enough to implement directly..."
- "I'll write a small utility rather than pull in machinery..."
- "A custom version gives us more control..."
- "I don't see them using the framework's feature, so I'll roll my own..." (did you look?)
- "It's just date math / just escaping / just a regex..."
- Writing infrastructure code without having checked the dependency manifest this session

### Use the Project Logger

NEVER log with raw `print`, `console.log`, `fmt.Println`, `System.out`, or `echo` in a codebase that has logging infrastructure. Find how this project logs and log that way.

Raw output bypasses everything the logging setup provides: levels, structured formatting, bound request context, and routing. A print statement is invisible to the aggregator, unfilterable in production, and uncorrelatable during incidents — which is to say, useless exactly when logs matter.

**When adding any log output:**
- Find the project's pattern first: search for `logger`, `log.`, `getLogger`, `createLogger` and copy how an existing module obtains its logger — module-level instance, injected dependency, factory call, whatever the convention is
- Never construct a fresh logger with default config (`logging.basicConfig`, `new winston.Logger()`) when a project factory or shared instance exists — that forks the configuration
- Use the project's conventions for the message itself: structured fields vs interpolated strings (`logger.info("order processed", order_id=oid)` vs f-strings, if that's the house style), message casing, and which context fields get attached
- Choose levels the way the codebase does: `debug` for diagnostic detail, `info` for normal operations, `warning`/`error` per the patterns in similar code — don't log routine success at `error` or failures at `info`
- If the project genuinely has no logging setup (scripts, tiny tools), plain output is fine — this rule is about bypassing infrastructure that exists

**Red flags that you're about to violate this:**
- "I'll just print a quick status message..."
- "console.log is fine for this..."
- "I'll set up a basic logger for this module..." (the project already has one)
- "The message text is what matters, not how it's emitted..."
- "I'll log the whole object so everything's visible..." (structured fields exist for this)
- Writing a log line without having looked at how the neighboring module logs

### Verify APIs Against the Installed Version

NEVER write code against a library API without confirming the project's installed version supports it. "The docs say it exists" is not verification — the docs describe a version; the lockfile describes reality.

You default to the newest API surface you know, but real projects pin older versions. An API that arrived in v6 is a runtime error in a v5 project, and it will pass every "is this method real" check because it is real — elsewhere.

**Before using a library API:**
- Check the pinned version in `package.json`, the lockfile, `requirements.txt`, `pyproject.toml`, `go.mod`, `Gemfile.lock`, or equivalent
- Confirm the specific method, option, or signature exists in that version — check the installed package source or the changelog, not just current docs
- If the codebase already uses the library, copy the call patterns it uses; they're version-correct by definition
- Pay special attention across major version boundaries — that's where APIs get added, renamed, and removed
- If a feature genuinely requires a newer version, say so explicitly and let the user decide whether to upgrade; do not silently write code that assumes the upgrade happened

**Red flags that you're about to violate this:**
- "The current documentation shows this method, so it's safe..."
- "This has been the standard API for a while now..."
- "I'll use the modern syntax for this library..."
- "Most projects are on the latest version anyway..."
- "The migration to the new API is straightforward, they've probably done it..."
- Writing a library call without having looked at a single version number in this session

### Verify Import Paths Exist

NEVER write an import path you haven't verified. The file's location, the relative depth, the alias mapping, and the exported symbol name are all facts about this repository — none of them can be inferred from what projects "usually" look like.

One import line encodes three or four separate guesses, and any wrong one breaks the build or, worse, resolves to the wrong module.

**Before writing any import:**
- Confirm the target file exists at that path (list the directory or search for the filename — don't trust your mental map of the tree)
- Confirm the symbol is actually exported from it, under that exact name, and whether it's a named or default export
- Count the relative depth from the *importing* file's real location; off-by-one `../` errors are the most common failure
- Path aliases (`@/`, `~/`, `$lib`, bare `src/...`) are defined per-project in `tsconfig.json`, `vite.config`, `webpack.config`, or equivalent — verify the mapping exists here before using one, and prefer however neighboring files import the same module
- The fastest verification: find an existing import of the same module elsewhere in the codebase and copy its exact form

**Red flags that you're about to violate this:**
- "The helpers are probably in utils/..."
- "Two levels up should reach the lib directory..."
- "This project surely has the @/ alias configured..."
- "It's most likely a default export..."
- "I'll write the import and fix the path if it errors..."
- Typing a path that you have not seen in a directory listing, a search result, or another file's imports this session

### Wire New Code Into the Codebase

New code isn't done when it's written — it's done when something reaches it. ALWAYS complete the wiring: the registration, mounting, export, scheduling, or call that makes your new code part of the running system.

A handler the router doesn't know about is a 404 with excellent internals. The artifact is half the task; the connection is the other half, and it usually lives in a file you haven't opened yet.

**For every new piece of code, identify and complete its connection point:**
- Route handlers → registered in the router/URL config
- Middleware → inserted into the middleware chain, in the right position
- Components → imported and rendered by an actual parent (and exported from the barrel file if the project uses them)
- Event handlers/listeners → subscribed to the emitter, queue, or signal
- Migrations → named/numbered so the migration runner picks them up
- Scheduled jobs → an actual schedule entry in the cron/scheduler config
- CLI commands → registered with the command group/parser
- DI services → bound in the container/module providers
- Find the connection convention by looking at how an *existing* sibling is wired, and wire yours the same way
- After wiring, trace the path once: from entry point (URL, event, schedule, import chain) to your code, confirming each hop exists. If you cannot complete the wiring (e.g., the parent component is ambiguous), say so explicitly — never present unwired code as a finished feature

**Red flags that you're about to violate this:**
- "The handler is implemented — the feature is complete..."
- "They'll hook it up wherever it fits best..."
- "The registration is trivial, I'll focus on the logic..."
- "I've created the component; integration is a separate concern..."
- "The framework probably auto-discovers this..." (verified, or assumed?)
- Finishing a feature without having edited any file that *references* your new code
