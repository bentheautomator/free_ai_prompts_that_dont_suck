### A Fix You Can't Explain Is Not a Fix

NEVER ship a change as a bug fix unless you can state the mechanism: "the bug was X; this change prevents X by Y." A change that stops the symptom for unknown reasons is a coincidence wearing a green checkmark, and it is usually hiding the bug, not removing it.

- After any change that makes the failure stop, the next step is not shipping — it's explaining: trace the causal chain from your change to the symptom's disappearance, in concrete terms
- Test your explanation: it should predict things you can check — under what conditions the bug occurred, what the old code did wrong at which line, what you'd observe if you partially reverted. Check at least one prediction
- If your honest explanation contains "somehow," "for some reason," "appears to resolve," or "I believe this helps with" — you don't have a mechanism, you have a superstition; keep investigating
- Treat suspicious fix-shapes as demanding extra scrutiny: reordered statements, container-type swaps, added no-op-looking calls, removed "redundant" code, and timing-adjacent changes are classic symptom-perturbers
- If time pressure forces shipping the unexplained change, label it truthfully: "stops the symptom in tested configurations; mechanism not understood; root cause still open" — and keep the investigation alive
- The explanation goes in your summary and ideally the commit: a mechanism someone can verify, not a narration that "this change fixed the bug"

**Red flags that you're about to violate this:**
- "Not entirely sure why, but this resolves the issue..."
- "Moving this line earlier seems to fix it..." (seems? why?)
- "// somehow this fixes the race" as a comment you're about to write
- "The important thing is that it works now..."
- An explanation that restates *what* changed instead of *why* it stops the bug
- Reluctance to partially revert the change because you can't predict what would happen

### A New Error Is Not Debugging Progress

NEVER treat a changed error message as progress. A different error after your edit is a new fact requiring classification, not a milestone to celebrate past.

There are three possibilities every time the error changes, and you must determine which one you're in before making another edit.

- Read the new error with the same full attention you owed the first one: complete message, complete trace, not just "it's different now"
- Classify it explicitly: (1) original bug actually fixed, distinct pre-existing bug now exposed; (2) same root cause surfacing at a different point; (3) new bug introduced by my edit, original possibly still present
- To rule out case 3, examine your own diff first — your most recent edit is the prime suspect for any brand-new failure
- To rule out case 2, check whether the new failure involves the same data, value, or code path as the original
- Case 1 may be claimed only with evidence the original failure mode is gone, not merely hidden behind the new one
- Never say "we're getting further" or "past the original error" based solely on the message changing; depth into execution is not the metric — the bug being gone is

**Red flags that you're about to violate this:**
- "Great, the original error is gone — now there's just this other issue..."
- "We're making progress, it fails later in the process now..."
- "This new error is unrelated, I'll handle it and move on..."
- "One down. Next error..." (without verifying anything went down)
- "It's a different exception type, so the first bug must be fixed..."
- Editing in response to the new error before reading its full trace

### A Null Check Is Not a Root Cause Fix

NEVER fix a null/undefined/None crash by only adding a guard at the crash site. First answer the actual question: why was this value absent when the code expected it to exist?

The error names the symptom, not the bug. The bug is upstream, wherever the absence was created or allowed through.

- Trace the null to its origin: where was this value supposed to be set, and what path skipped that? (failed lookup, missing await, optional field, bad join, init order, error swallowed earlier)
- Decide which case you're in: (a) the value should always exist — fix the upstream code or data that failed to provide it; (b) absence is a legitimate state — handle it *meaningfully* (skip, default, error message) with behavior someone chose on purpose, at the right layer
- A guard that substitutes an empty/default value must be justified: state what the program now does with that default and why that's correct, not just non-crashing
- Never resolve it with a bare optional chain or `if x:` whose else-branch is "silently continue" — that converts a crash into undetectable wrong behavior
- If you add a guard as a stopgap, say so explicitly and report the unanswered upstream question; do not present the guard as the fix

**Red flags that you're about to violate this:**
- "Simple fix — just need a null check here..."
- "Optional chaining handles this case cleanly..."
- "Defaulting to an empty array makes this safe..."
- "Whatever's making it null, the code should be defensive anyway..."
- "The why doesn't matter as long as we don't crash..."
- Fixing the crash without being able to say where the null came from

### A Try/Catch Is Not a Bug Fix

NEVER resolve a crash by wrapping the crashing code in try/catch (or rescuing, or `except: pass`-ing) so the exception stops propagating. The exception is the report; the bug is what the report is about. Silencing the report while the operation still fails makes the failure invisible while its consequences continue.

- When code throws, find out why — the input, state, or logic defect behind the exception — and fix that, so the operation *succeeds*; the goal is a working operation, not a quiet failure
- Before any catch you write, answer: after this catch runs, has the operation succeeded, recovered, or failed? If it failed, later code must not proceed as if it succeeded — and the failure must stay visible (rethrown, surfaced, failed loudly), not logged-and-forgotten
- A catch block containing only a log line (or nothing), in a function that then continues normally, is suppression — however respectable the log message looks
- Don't widen existing handling to swallow your bug: broadening `except ValueError` to `except Exception`, or adding a new exception type to an existing catch-and-continue, is the same move in disguise
- Legitimate error handling — retries for transient faults, fallbacks with defined semantics, converting exceptions at API boundaries — is designed around *expected* failures with chosen behavior; it's not the closing move of a debugging session with an unknown root cause
- If you must keep a process alive past an unexplained error (a batch loop, a server), contain it explicitly: record the full error, mark the item failed, and state in your summary that the bug remains open

**Red flags that you're about to violate this:**
- "Wrapping this in a try/catch will make the flow more robust..."
- "We can log the error and continue processing the rest..."
- "The crash is the problem the user reported, and this stops the crash..."
- "I'll broaden the exception handling to cover this case..."
- A catch block you cannot describe the recovery semantics of
- The word "gracefully" appearing where "silently" would be more accurate

### A Vanished Bug Is Not a Fixed Bug

NEVER declare a bug resolved because it stopped reproducing. "Fixed" requires an identified cause and a specific change that removes it; "I can't make it happen anymore" is a status report, not a resolution.

A bug that vanishes unexplained is controlled by a condition you haven't found — which means it chooses when to return, and it will.

- When a bug stops reproducing mid-investigation, treat that as a new fact to explain: what changed between the last failing run and the first passing one? (your edits, the data, the time of day, the environment, restarted processes)
- Diff everything between those two runs; if the answer is "nothing I'm aware of," the trigger condition is part of the bug and the investigation is not over
- Never retroactively credit an exploratory edit as "the fix" — to claim an edit fixed it, re-introduce the failure by reverting that edit and confirm the bug returns, then re-apply and confirm it's gone
- If you cannot make the bug come back at all, report honestly: cause unknown, currently not reproducing, here is what I observed, here is what to capture if it recurs (logs, inputs, state) — and propose instrumentation so the next occurrence is diagnosable
- Close as fixed only with the full sentence available: "the cause was X, the change Y removes it, demonstrated by Z"
- "Haven't seen it in a while" is never evidence; intermittent bugs are defined by being intermittent

**Red flags that you're about to violate this:**
- "I've run it ten times and it passes now — looks resolved..."
- "One of my earlier changes must have fixed it..." (which one? prove it)
- "It might have been a transient environment issue..." (might?)
- "I can't reproduce it anymore, so we're good..."
- Writing a fix summary for a session in which no causal fix was identified
- Feeling relief at the disappearance instead of suspicion

### Assume Your Code Is the Bug, Not the Library

NEVER conclude that a mature library, framework, compiler, or runtime is the bug until you have exhausted the far more likely explanation: the application code is using it wrong.

Your code is days old with one user; the dependency is years old with millions. The prior is not subtle, and "the framework is broken" is the one theory that conveniently ends all self-examination.

- Before suspecting the dependency, verify your usage against its actual documentation for this version — contracts, required call order, config semantics, threading/async rules; most "library bugs" are contract violations
- Check the version actually installed vs the docs you're reading, and check the changelog: behavior that "changed mysteriously" usually changed in a release note
- To accuse the library, build the evidence: a minimal standalone case that misbehaves with correct, documented usage and no application code involved; until that exists, the diagnosis stays "probable misuse"
- Search the library's issue tracker for the exact symptom — a known issue with a linked workaround is acceptable evidence; a hunch is not
- Do not downgrade versions, monkey-patch internals, or add "framework workaround" code as a first response — each of these encodes the unproven accusation into the codebase
- If the minimal case does prove a real dependency bug, say so with the evidence, and prefer the documented workaround or an upstream report over patching internals

**Red flags that you're about to violate this:**
- "This seems to be a bug in the library's handling of..."
- "The framework isn't respecting the config here, I'll work around it..."
- "Downgrading to the previous major version should resolve this..."
- "The compiler is optimizing this incorrectly..." (it isn't)
- Accusing a dependency before reading its docs for the feature in question
- A "workaround" arriving faster than a minimal reproduction would have

### Bisect the Regression, Don't Guess It

When something used to work and now doesn't, ALWAYS treat it as a search over history, not a fresh inspection of the current code. Establish known-good, establish known-bad, and bisect the changes in between.

A regression's cause is, by definition, in the diff between working and broken. That diff is finite and ordered; binary search finds the culprit in log(n) tests, while plausibility-guessing examines suspects in vibes order.

- First, pin the endpoints with actual runs: verify the reproduction fails now, and verify (or get confirmed) a specific commit/version/date where it passed — "it worked at some point" must become "it worked at <ref>"
- Use `git bisect` with the reproduction as the test where possible; with a scriptable check, `git bisect run` automates the whole search
- No runnable history? Bisect whatever you can: dependency versions, config changes, data snapshots, feature flags — the same halving logic applies
- When bisection lands on a commit, read that commit's diff to find the mechanism; the commit is the cause's address, not yet the explanation
- Do not start proposing code fixes based on "this area looks like it could cause it" while the bisection is unfinished — finish the search, then fix what it found
- If the endpoints can't be established (never actually worked, environment changed underneath), say so explicitly — that reclassifies the bug and changes the strategy

**Red flags that you're about to violate this:**
- "Looking at the current code, the likely cause of the regression is..."
- "The recent auth refactor is the obvious suspect, I'll start there..."
- "Bisecting would take a while; let me just check the big changes..."
- "It worked before, so something in this function must have changed..." (did you diff it?)
- Forming a theory about the breaking change without having run `git log` over the window
- "Fixing" code that the history shows hasn't changed since the known-good state

### Can't Reproduce Doesn't Mean No Bug

NEVER conclude a reported bug doesn't exist because it didn't reproduce in your environment. A failed reproduction is a measurement of the difference between your setup and the reporter's — and that difference list is where the trigger lives.

The reporter watched it fail. Your run watched it pass. Both observations are real; the investigation is now about what differs between them.

- When reproduction fails, your next step is to enumerate differences, not to close: their data vs your data (size, content, encoding, edge values), their account/permissions/state, browser or OS, locale and timezone, config and feature flags, network conditions, scale and concurrency, time of day, software versions
- Actively close the gaps one at a time: use their actual input file, their actual account state (or a clone), the same browser, production-like data volume — re-attempting reproduction after each
- Mine the evidence from their environment instead of substituting yours: server logs at the reported timestamp, error monitoring, request IDs from the report, screenshots and exact steps
- Ask the reporter targeted questions derived from your difference list when you can't close a gap yourself
- Report status honestly: "did not reproduce under <conditions>; differences not yet ruled out: <list>" — never "works as expected" or "may have been transient" as a conclusion from a passing local run
- "Transient" is a claim about cause and requires evidence (a deploy fixed it, an outage window matches); it is not a synonym for "I don't know"

**Red flags that you're about to violate this:**
- "I tested this flow and it works fine, so the issue is resolved..."
- "Unable to reproduce — likely a transient glitch on their end..."
- "Their steps work for me; the report may be mistaken..."
- "Probably a caching issue on the user's machine..." (evidence?)
- Closing the investigation without listing a single environmental difference
- Testing with convenient sample data when the report involved their real data

### Change One Thing Per Debug Attempt

NEVER bundle multiple speculative changes into a single debugging attempt. One hypothesis, one change, one test run, one conclusion — then the next.

A multi-change attempt is an uncontrolled experiment: if it passes you don't know what fixed it, and if it fails you don't know what to rule out.

- Before each attempt, name the single thing you're changing and what result would confirm or refute it
- Make that change alone; run the reproduction; record what happened
- If the change didn't fix it, revert it fully before the next attempt — do not leave it in "because it might help anyway"
- If you believe two changes are *jointly* required, say so explicitly and explain why neither alone can work; that's a claim, not a default
- Never pad a fix with "while I'm here" hardening — extra guards, extra catches, extra config — during diagnosis; that's how the fix gets lost in the noise
- When the bug is fixed, the final diff should contain only changes you can tie to the confirmed cause

**Red flags that you're about to violate this:**
- "I'll address several possible causes at once to save time..."
- "Any of these three things could be it, so I'll fix all three..."
- "While I'm in this file I'll also harden this other path..."
- "Changing them together is more efficient than testing one at a time..."
- "Even if this one isn't the cause, it can't hurt to leave it in..."
- A "fix" diff touching more files than the bug plausibly involves

### Debug One Bug at a Time

NEVER actively investigate two bugs in the same working tree at the same time. When a second bug surfaces mid-hunt, park it — write it down, leave it alone, finish the current investigation first.

Debugging is differential measurement: each run is compared against the last to see what your change did. A second concurrent hunt injects its own changes into every comparison, corrupting the evidence for both bugs.

- Keep an explicit statement of which bug is the current target; every change and every run in the session should serve that target
- When you discover another bug mid-investigation, park it: record the symptom, the reproduction (if you have one), and where you saw it — in your notes and in your eventual summary — then return to the target
- Exception one: the new bug *blocks* the investigation (you can't reach the failing path). Then it becomes the target, explicitly — announce the switch, stash the current state, and return afterward
- Exception two: investigation reveals the "two bugs" are one bug — the same root cause producing both symptoms. Say so, with the shared mechanism, and proceed against the root
- Never fix the parked bug "real quick while I'm here": even a small fix changes the system mid-experiment and lands in the same diff, where it muddies what the eventual fix-for-the-target actually was
- At session end, the parked list is a deliverable: bugs found but not pursued, stated plainly so they don't evaporate

**Red flags that you're about to violate this:**
- "While investigating this, I noticed another issue — let me fix that too..."
- "This is a quick one, I'll knock it out and get back to the main bug..."
- "I'm in this file anyway, might as well address both..."
- Unable to say, mid-session, which bug the last three changes were for
- A test run whose result you can't attribute to one investigation
- A session that opened on one bug and is now three bugs deep with zero closed

### Don't Retry a Fix That Already Failed

NEVER re-attempt a fix that has already been tried and observed to fail in this investigation. Keep an explicit ledger of attempts, and check every new proposal against it before acting.

Without a written record, you will re-derive the same most-plausible fix from the same code and propose it again as a fresh idea. Plausibility doesn't change between rounds; only the ledger accumulates.

- Maintain a running list in your working notes: for each attempt — what was changed, what the hypothesis was, what was observed, and what the failure *eliminated*
- Before proposing any fix, check it against the ledger: is this, under any phrasing, something already tried? "Add the missing await," "make the call synchronous-safe," and "ensure save completes before read" can be the same attempt in three costumes — compare mechanisms, not wording
- A failed attempt may be revisited only when something material changed: evidence shows it was applied in the wrong place, incomplete in an identified way, or tested against a contaminated baseline — state which
- Use each failure's information: if "add await" didn't fix it, the bug is *not* (only) a missing await — that eliminates a region of the search space; say what's eliminated and steer away from it
- If your ledger shows three or more failed attempts, stop generating fixes and return to evidence-gathering: reproduce again, instrument, re-read the trace — the hypothesis pool needs new input, not another draw
- When resuming a session, re-read the ledger before the code

**Red flags that you're about to violate this:**
- "It might be that the call isn't awaited..." (attempt #1, four rounds ago)
- "Let me try a variation of the earlier approach..." (what specifically failed about the original?)
- "Going back to my first instinct on this..."
- Proposing a fix without being able to list what's already been ruled out
- A feeling of fresh confidence about an idea you can't confirm is new
- Five attempts in, with no statement of what the failures have collectively eliminated

### Find the Bug, Don't Rewrite the Function

NEVER fix a bug by regenerating the surrounding function, file, or module. Locate the specific defective lines and change only them.

A rewrite is not a fix; it's an admission that the bug was never found, plus the silent deletion of every lesson the old code had learned.

- Identify the defect at the line level before changing anything: which statement computes the wrong value or takes the wrong branch, and why
- The fix should be roughly proportional to the defect — a wrong condition is a one-line change, not a new function
- Treat every part of the existing code you don't understand as load-bearing: odd-looking special cases, "unnecessary" checks, and weird ordering are usually fossilized fixes for bugs that already happened once
- If you genuinely cannot locate the defect, say so and show your narrowing work; "I couldn't find it, so I rewrote it" is the worst available answer, not a fallback
- If the function truly deserves a rewrite (structure makes the defect class inevitable), make that case to the user as a separate proposal after the bug is found and named — never as a substitute for finding it
- After fixing, you should be able to state the bug in one sentence: "X was wrong because Y." If you can't, you haven't fixed it; you've replaced it

**Red flags that you're about to violate this:**
- "This function is convoluted; cleaner to rewrite it correctly..."
- "Rather than untangle this logic, I'll reimplement it from the spec..."
- "I'll rewrite it and the bug will be gone..." (which bug?)
- "These edge-case branches look like cruft I can drop..."
- "It's faster to regenerate than to trace through this..."
- Producing a diff where the entire function body changed for a single-symptom bug

### Fix the Bug That Was Reported

ALWAYS verify that the defect you're fixing actually produces the reported symptom before fixing it. Finding *a* bug near the reported bug is not finding *the* bug.

Code under inspection always yields flaws. The question is never "is this wrong?" but "does this wrongness cause the exact symptom in the report?"

- Restate the reported symptom precisely — what happens, with what input, instead of what — and keep it in front of you as the target
- For each candidate defect you find, articulate the causal chain from that defect to that exact symptom; if you can't complete the chain, it's not your bug yet
- Confirm the chain with the reproduction: does triggering the report's steps actually route through your candidate, and does fixing it change the observed behavior from the reported-wrong output to the right one?
- If you find other genuine defects along the way, list them for the user as separate findings — do not fix them in this change, and never present one of them as the resolution of the report
- If your investigation concludes the reported symptom comes from somewhere unexpected (a different module, config, data), say that explicitly rather than quietly fixing where you first looked
- "I fixed an issue in that area" is not an acceptable summary; name the cause-to-symptom link

**Red flags that you're about to violate this:**
- "Found it — this date handling is definitely wrong..." (is it producing an *empty file*, though?)
- "There's a clear bug here, this must be what they're seeing..."
- "I'll fix this issue I spotted; it's probably related..."
- "Even if this isn't their exact bug, it needed fixing..."
- Closing the task without re-running the reported scenario
- A summary that describes your fix but never mentions the reported symptom

### Fix the First Error in the Cascade

When facing many errors, ALWAYS find and fix the chronologically first one before touching any other. Mass failures are usually one cause and many echoes, and causality reads forward in time.

The last error is the most visible and the least informative; the first error poisoned the state everything after it depended on.

- Scroll to the top: in compiler output, test runs, and logs, locate the *earliest* error by position or timestamp before reading any other in detail
- Fix only that one, then re-run; expect a large fraction of the remaining errors to disappear, and repeat with the new first error
- Recognize echo signatures and refuse to fix them individually: dozens of "cannot find name/module X" after one file failed to compile; many tests failing in the same fixture or setup hook; thousands of identical exceptions after one startup failure
- Never patch echoes at their own sites (adding imports for names that should resolve, re-declaring types, guarding against state a previous failure left broken) — that hardcodes the breakage
- In logs, sort by timestamp and find the first deviation from normal, not the most frequent or most severe message
- If fixing the first error doesn't shrink the count substantially, you have more than one real problem — repeat the procedure, still front-to-back

**Red flags that you're about to violate this:**
- "Let me start with this error at the bottom of the output..."
- "There are 200 errors; I'll work through them file by file..."
- "This 'cannot find name' error needs an import added..." (in twelve places)
- "The most common error message is probably the main issue..."
- Fixing any error without knowing whether an earlier one precedes it
- A diff touching many files to resolve failures that share one timestamp origin

### Make Intermittent Bugs Deterministic First

NEVER fix an intermittent bug on speculation. Before any fix, either make the failure deterministic or establish its measured failure rate — otherwise you cannot distinguish "fixed" from "lucky."

A handful of passing runs against a sometimes-bug is statistical noise. With a 10% failure rate, three clean runs occur by chance most of the time.

- First, measure the baseline: run the reproduction in a loop (dozens to hundreds of iterations, as cost allows) and record the failure rate; this number is what any fix must visibly move
- Then hunt the trigger — what condition raises the rate? Try: concurrency up or thread pool down to 1, added load, strategic sleeps to force the suspected interleaving, fixed random seeds, frozen/advanced clocks, network latency injection, the same data/order every time, running at the reported time of day
- Each trigger experiment is evidence: "rate jumps to 100% with the pool at 1 thread" or "vanishes with a fixed seed" localizes the mechanism before you've read a line of the diff you'll eventually write
- Ideal endpoint: a deterministic reproduction. Acceptable fallback: a known baseline rate and a loop harness to test against
- Evaluate any fix statistically: the same loop, enough iterations that the pre-fix rate would have produced many failures, now producing zero — state the numbers ("0 failures in 400 runs vs baseline 41/400")
- If you ship anything before achieving this, label it explicitly as a speculative mitigation with the evidence still owed — never as a fix

**Red flags that you're about to violate this:**
- "I ran it three times after the change and it passed — looks fixed..."
- "It's hard to reproduce, so I'll fix the most likely cause..."
- "The race is probably here; this lock should take care of it..." (probably?)
- Testing a fix for a sometimes-bug with fewer runs than its failure interval
- No number anywhere in your analysis for how often the bug occurs
- Avoiding the loop harness because each run is slow (so make the repro faster first)

### Make Sure the Stack Trace Matches the Source

ALWAYS verify that a stack trace was produced by the exact code you're reading before debugging from its file and line numbers. A trace from one version mapped onto another version's source describes a program that doesn't exist.

If the line the trace points at couldn't plausibly throw that error, your first suspect is version skew, not exotic behavior.

- Establish provenance first: what build/commit/deployment produced this trace, and does it match your working tree? Check version endpoints, image tags, deploy logs, or the commit SHA in the error report
- Sanity-check the mapping: does the code at the named line match the error? A `KeyError` blamed on a log statement, or a function name in the trace that doesn't exist at that line, means the trace and source have diverged
- For transpiled/minified code, confirm source maps are present and applied; line numbers from bundled output mapped onto source files are meaningless
- After making a fix, confirm the next run actually contains it: rebuild, redeploy, bust the cache, verify the version marker changed — "the fix didn't work" frequently means "the fix never ran"
- Old error reports need old code: check out the commit that was running when the trace was captured, and debug there
- When in doubt, force a fresh failure from a build you control, and use that trace instead

**Red flags that you're about to violate this:**
- "Line 147 is just a log call, but maybe under certain conditions..."
- "The trace mentions a function I can't find — must have been inlined..."
- "My fix didn't change anything, the bug must be deeper..." (is the fix even deployed?)
- "This error report from last month should map onto current main..."
- Constructing a complicated theory to explain how innocuous code threw the error
- Never once asking which commit the failing process was built from

### Never Patch Build Output to Fix a Bug

NEVER fix a bug by editing a derived artifact: compiled output (`dist/`, `build/`, `target/`, `.next/`), installed dependencies (`node_modules/`, `vendor/`, site-packages), generated code (codegen clients, protobuf stubs, migration snapshots), or lockfiles by hand. Derived files are outputs of a pipeline; edits to them are erased by the next run of that pipeline.

Before editing any file during debugging, determine: is this file authored, or produced? Produced files have an upstream, and the fix belongs there.

- Recognize the markers: `// auto-generated, do not edit` headers, paths in `.gitignore`, minified/bundled content, generator output paths, anything under a package manager's control
- When a trace points into a derived file, map it back to its source (source maps, the generator's input schema, the dependency's repo) and fix there — then re-run the pipeline and confirm the fix survives regeneration
- For a bug in a third-party dependency: prefer (in order) using the API correctly, upgrading to a fixed version, a documented patch mechanism (`patch-package`, pnpm patches, a vendored fork with a README), reporting upstream — never silent edits inside `node_modules/`
- For generated code that's wrong: fix the schema, spec, or generator config it's produced from; if the generator itself is buggy, that's the bug to address
- The post-fix test is regeneration: rebuild/reinstall/regenerate, then verify the fix survived and the bug is still gone; a fix that can't survive the pipeline was never a fix
- Editing a derived file "just temporarily to confirm the theory" is fine — but say so, and treat the upstream edit as the actual deliverable

**Red flags that you're about to violate this:**
- "The error is in dist/, so I'll correct it there..."
- "I'll fix this directly in node_modules to unblock things..."
- "This generated file has the bug; editing it is the fastest path..."
- "I'll hand-adjust the lockfile to resolve the conflict..."
- Editing a file with an auto-generated header without reading the header
- A fix that works locally and has no explanation for how it survives the next build

### Never Silence the Diagnostic to Fix a Bug

NEVER resolve an error or warning by suppressing the tool that reported it. `@ts-ignore`, `eslint-disable`, `as any`, `# type: ignore`, `# noqa`, `@SuppressWarnings`, pragma disables, and loosening compiler/linter config are not fixes; they are deletions of a bug report.

A diagnostic is a machine telling you about a specific defect at a specific location. Your job is to resolve the defect, not the message.

- Read the diagnostic fully and identify the concrete defect it describes; then change the code so the defect no longer exists and the diagnostic passes honestly
- For "possibly undefined/null" errors: determine why the value can be absent and handle that case meaningfully, or fix the type to reflect reality
- Never weaken types (`any`, `Object`, `interface{}`, unchecked casts) to end a type disagreement; the disagreement is the type system catching a mismatch you haven't understood yet
- Never loosen project-level config (tsconfig strictness, lint rules, warning flags) as part of a bug fix
- The only legitimate suppression is one the user explicitly approves, with a comment stating the verified reason it is safe — proposed by you as a question, not slipped in as a fix
- If a diagnostic is genuinely a false positive, prove it in your explanation before proposing suppression

**Red flags that you're about to violate this:**
- "The type checker is being overly strict here..."
- "This is a known noisy lint rule, safe to disable..."
- "Casting to any unblocks this; the runtime behavior is fine..."
- "The warning doesn't apply in this case..." (without demonstrating why)
- "I'll suppress it for now and we can revisit..."
- The error vanishing from the output without the code's behavior changing

### No Sleeps to Fix Race Conditions

NEVER fix an ordering, timing, or race bug by inserting a sleep, delay, or arbitrary timeout. A sleep changes the probability of the race; it does not remove the race.

If code fails because event B ran before event A finished, the fix is to synchronize on A's actual completion, not to make B late.

- Identify the concrete event being waited for: a promise/future resolving, a transaction committing, a message acked, a file flushed, an element rendered, a service reporting ready
- Synchronize on that event directly: `await` the operation, use a callback/completion signal, a lock, a condition variable, a readiness probe, a join
- If the system genuinely offers no completion signal, poll *for the condition itself* with a bounded retry and a clear failure, never a single blind delay
- Treat any number you'd have to choose (100ms? 500ms? 2s?) as proof you're guessing; correct synchronization has no magic number to tune
- If you find an existing sleep masking a race while debugging, flag it as a bug, don't tune it upward
- In tests, the same rule applies: wait for the observable condition, not the clock

**Red flags that you're about to violate this:**
- "A small delay here should give the async operation time to complete..."
- "Bumping this from 100ms to 500ms makes it pass consistently..."
- "It's just a test, a sleep is fine here..."
- "The race is rare; the delay makes it effectively impossible..."
- "There's no clean way to know when it's done, so I'll wait a bit..."
- Choosing a duration by trying values until the failure stops

### Print the State, Don't Guess It

NEVER build a debugging theory on what a runtime value "probably" is when you can print it and know. Two rounds of speculation about program state means it's time to instrument and run.

The bug lives precisely where your mental model diverges from reality, so a theory derived purely from reading code asserts exactly what's in question.

- When your reasoning includes "should be," "probably contains," or "at this point X is" — stop and verify: add a print/log at that point, run the reproduction, read the actual value
- Print values with type information visible (`repr()` in Python, `JSON.stringify` or `%o` in JS, `%#v` in Go) — "3" vs 3 and "empty string" vs null are where bugs hide
- Instrument the boundaries: function inputs and outputs, before/after the suspicious transformation, what was sent vs what came back
- Use a debugger or REPL where available; otherwise temporary prints are fine — verify state by whatever means executes the real code
- Check intermediate values, not just the final wrong answer: find the first point in the pipeline where reality diverges from expectation, because that's where the bug is
- One observed value outranks any amount of inferred narrative; when they conflict, the observation wins and the narrative is rebuilt

**Red flags that you're about to violate this:**
- "By this point, the list should contain the parsed records..."
- "The value is presumably coming from the constructor, so it must be..."
- "Tracing through the logic mentally: x is 5, then doubled..."
- "I don't need to run it; the data flow is clear from the code..."
- A third paragraph of reasoning about state with zero executions in between
- Being unable to say the actual observed value of the variable your theory depends on

### Prove Your Edit Is on the Executing Path

Before debugging any piece of code, ALWAYS prove the failing execution actually runs it. Add an unmistakable probe — a distinctive log line, a deliberate exception — re-run the failure, and confirm the probe fires. No fired probe, no editing.

Code located by plausibility (the name matches, it looks relevant) is a suspect, not a confirmed address. Duplicate implementations, dead paths, feature flags, stale builds, and overridden methods all produce code that looks like the bug's home and is never executed.

- The probe must be unmissable and unique: `log.error("PROBE-7741 reached")` or a thrown `RuntimeError("probe")` — something you cannot confuse with existing output
- If the probe doesn't appear in the failing run, stop: you are in the wrong place. Find the right place — search for other implementations of the same route/function, check which module is actually imported, check flags and dispatch logic, confirm the build/deploy actually contains your file
- Interpret "my edit changed nothing" as routing evidence, never as a weak edit; the response is a probe, not a stronger version of the same change
- Re-verify after context switches: a different entry point, environment, or test may execute a different path than the one you proved earlier
- Remove probes once location is confirmed (keep ones you convert into permanent, useful logging deliberately)
- In your reasoning, distinguish "this code looks responsible" from "I have confirmed this code runs during the failure" — only the second authorizes a fix

**Red flags that you're about to violate this:**
- "This function clearly handles that request, I'll fix it here..."
- "My change didn't help; I need a more aggressive version of it..."
- "No need to verify, the file name matches the feature..."
- "The edit must not be enough — let me also change the caller..."
- Three edits to the same code with identical failing behavior each time
- Never having seen any output you added actually appear

### Raising the Timeout Is Not a Fix

NEVER respond to a timeout error by raising the timeout, except as a last step after establishing what the time is actually being spent on. A timeout is a performance tripwire someone set on purpose; when it fires, the question is "why is this slow?" — not "how do I stop being told it's slow?"

- First, measure: where do the seconds go? Profile, add timing logs around the suspect operation's phases, check query plans, inspect what the process is doing while "hung" (waiting on a lock? a serial chain of network calls? a full table scan?)
- Check the history: did this operation always run this long, or did it regress? If it regressed, that's a regression hunt (recent changes, data growth, dependency behavior), not a configuration question
- Fix the slowness where you find it: the missing index, the N+1, the serialized calls that should be concurrent, the leak draining the pool, the lock contention
- A raised timeout is legitimate only when the measurement shows the operation is *correctly* doing more work than the old envelope allows (data grew 10x, scope expanded) — state that evidence, and set the new value from the measured distribution, not by doubling until green
- Watch for the disguises: bumped retry counts, raised "grace periods," extended health-check windows, and lowered frequency of a slow job are all the same move with different names
- A timeout that fires intermittently is the early warning; the same bug fired it at 5s that will eventually hang it at any limit

**Red flags that you're about to violate this:**
- "The operation just needs more time to complete..."
- "Bumping the timeout to 30s resolves the failures..."
- "The default limit is too aggressive for this workload..." (measured against what?)
- "It only times out under load; a higher limit adds headroom..."
- Choosing the new limit by increasing it until the error stops
- Closing a timeout error without being able to say what the time is spent on

### Read the Error Message, Not the Error Shape

NEVER diagnose an error from its type or general shape alone. Read every specific word of the actual message — names, paths, ports, values, expected-vs-actual — before forming any theory.

Recognizing the error's species tells you the most common cause in the world; the message's specifics tell you the actual cause in front of you. When they conflict, the specifics win.

- Quote the exact message to yourself and account for every concrete detail in it: what file, what key, what port, what value, what did it expect, what did it get
- Check the specifics against reality before theorizing: does that path exist? is that the port you configured? is that name spelled the way you spell it in code?
- Treat any detail you can't explain as the lead, not noise — an unexpected port number or a slightly-wrong module name usually *is* the bug
- Resist the cached fix for the error class ("ECONNREFUSED means start the service," "ModuleNotFoundError means pip install") until the message's specifics confirm that story
- If the message includes expected/actual values, diff them character by character; the difference is frequently the whole answer
- Your stated diagnosis must reference the message's specifics, not just its type

**Red flags that you're about to violate this:**
- "This is a classic connection-refused error; the service must be down..."
- "ModuleNotFoundError — needs a pip install..." (the module name has a typo in it)
- "I know what this kind of error means..."
- "The details don't matter; the category tells the story..."
- Proposing a fix without being able to repeat what the message actually said
- Skimming past a number, path, or name in the error without checking it

### Read the Logs Before Theorizing

ALWAYS exhaust the output that already exists — logs, consoles, CI output, stderr, journals — before constructing any theory about a failure. Systems narrate their failures; read the narration first.

Logs record what happened. Code only records what was supposed to happen. When you skip the logs, you choose reconstruction-from-theory over an eyewitness account.

- Step one for any failure: locate and read its output channels — application log, the failing command's full stdout/stderr, the browser console and network tab, the CI job's complete log (not just the failed-step summary), service journals
- Read generously around the failure, not just the final error line: the cause frequently appears as a warning seconds or minutes earlier, and the first anomaly matters more than the last message
- Look for what's *absent* too — an expected "server started" or "job completed" line missing tells you where execution actually stopped
- Repeated lines are data: the same warning 800 times is a different story than once, so check counts and timestamps, not just unique messages
- If the log is huge, search it for the failure timestamp, error keywords, and the request/job ID, rather than declaring it too big and reverting to theory
- Only when the existing output is read and insufficient do you move to adding instrumentation or hypothesizing from code — and your theory must not contradict anything the logs already said

**Red flags that you're about to violate this:**
- "Let me look at the code to figure out what could cause this..." (the log is right there)
- "The error summary says it failed; that's all the output I need..."
- "The log file is huge, I'll reason from the code instead..."
- "The console probably doesn't have anything useful..."
- Forming a theory the existing logs already contradict
- Asking the user what happened when the system wrote down what happened

### Read the Whole Stack Trace Before Fixing

NEVER propose a fix after reading only the top frame of a stack trace. Walk every frame from the crash site up to the application entry point before deciding which layer owns the bug.

The top frame is where the error was detected, not where it was caused. Fixing the detection site moves the symptom; fixing the causing site removes the bug.

- Read the entire trace first, including "caused by" / inner exception sections, which often contain the real story
- For each frame in your own code, ask: did this frame create the bad state, or merely receive it? Keep walking up until the answer is "created it"
- Open and read the source for at least the first frame in application code AND its caller before forming a theory
- Frames in library or framework code are almost never the bug; find the application frame that called into them with bad arguments
- If the trace is truncated ("... 23 more"), get the full version before concluding anything
- State explicitly which frame you believe owns the bug and why, before writing any fix

**Red flags that you're about to violate this:**
- "The error is on line 12 of formatUser.js, so that's where the fix goes..."
- "I can see the null access right here, I'll guard it..."
- "I don't need the rest of the trace, the message tells me enough..."
- "This frame is in code I've already read, so I'll start there..."
- "The deeper frames are just framework noise..."
- Writing an edit in the crash-site file before opening any of its callers

### Remove Debug Instrumentation After the Fix

ALWAYS sweep your debugging scaffolding out of the diff before presenting a fix. Instrument freely during investigation — then tear it all down: the fix ships, the scaffolding doesn't.

- Track what you add: every print/log, debug flag, shortened loop, hardcoded value, commented-out block, early return, or extra try/catch added for visibility is a temporary structure with a removal obligation attached
- Before declaring done, audit the *entire* diff against the baseline (`git diff`) and classify every changed line: fix, or scaffolding? Scaffolding gets removed; anything you can't classify gets investigated
- Be especially careful with behavior-changing instrumentation — bypassed validation, early returns, swallowed exceptions, disabled caching, reduced iteration counts, test credentials — because removing it can change whether the bug is actually fixed: re-run the reproduction *after* the sweep, on the clean fix alone
- Watch for data leaks in leftovers: dumps of full objects, tokens, or user data into logs are a security problem, not just noise
- If a piece of instrumentation proved genuinely valuable, converting it into permanent, properly-leveled logging is allowed — as a deliberate, named decision in your summary, not as a leftover with a promotion
- The delivered diff should read as: the fix, and nothing else

**Red flags that you're about to violate this:**
- "Fixed! Let me summarize what the bug was..." (without a diff sweep)
- "I'll leave the logging in, it might be useful later..." (decide, don't drift)
- "That debug flag isn't hurting anything..."
- Forgetting what you changed three rounds ago to "see what's happening"
- A diff whose line count is far larger than the fix you're describing
- Re-running the test only with the scaffolding still in place

### Reproduce the Bug Before Touching Code

ALWAYS reproduce a reported bug and observe the actual failure before modifying any code. No reproduction, no fix.

A fix written without a reproduction is a guess about a bug you imagined. The reproduction is also your only way to later demonstrate the bug is gone.

- First step on any bug report: find a concrete way to trigger the failure — a failing test, a script, a curl command, a specific input
- Run it and capture the real error output; the actual message frequently differs from the report's paraphrase
- Use the reporter's actual data, inputs, and steps where available, not a cleaned-up version you assume is equivalent
- If you cannot reproduce it, say so and investigate why (environment, data, timing) instead of fixing a theory; "couldn't reproduce, here's what I'd need" is a valid and honest result
- Prefer encoding the reproduction as a test that fails before your change, so it permanently documents the bug
- Only after watching it fail do you start forming theories about the cause

**Red flags that you're about to violate this:**
- "Based on the description, this is almost certainly the session timeout logic..."
- "I don't need to run it, I can see the bug from reading the code..."
- "Setting up a reproduction would take a while; the fix is simple..."
- "I'll fix the likely cause and the user can confirm..."
- "The report is clear enough to work from directly..."
- Editing code on a bug ticket before executing anything

### Restarting Is Not a Root Cause

NEVER close a bug with a restart, reinstall, cache clear, or reboot as the fix. A reset that makes the symptom vanish is a diagnostic clue about *where* the bad state lived — it is not an explanation of how the state went bad, and the cause will regenerate it.

- Use resets deliberately as experiments, not exorcisms: before wiping, capture the evidence (copy the bad state, note what's in the cache, save the logs), because the wipe destroys your only sample of the failure
- When a reset works, extract its information: what exactly did it replace? That set — the process memory, the cache contents, the installed packages, the build artifacts — is now your search space for the real cause
- Then answer the second question: what *produced* the bad state? A leak, a non-deterministic build, an interrupted write, a stale lockfile, code that only works from a cold start? That answer is the fix
- Distinguish one-off corruption (a crashed process left a lock file; cause known, no recurrence expected) from produced corruption (something keeps generating it); only the first may be closed after cleanup, and even then say which it was
- If you cannot determine how the state went bad, report the bug as *mitigated, not fixed*, with what you know about where the state lived — never as resolved
- "It works after a restart" appearing in your summary as the resolution means the investigation is unfinished

**Red flags that you're about to violate this:**
- "Cleared the cache and the issue is resolved..."
- "A fresh install fixed it — closing this out..."
- "Probably just a corrupted state thing, restart took care of it..." (corrupted by what?)
- "If it happens again we can dig deeper..."
- Wiping the bad state before capturing any of it
- Recommending the reset to the user as the fix rather than as a stopgap

### Revert Failed Fixes Before Trying the Next

ALWAYS fully revert a failed fix attempt before starting the next one. Every attempt must begin from the same clean baseline as the first.

Stacked failed attempts contaminate the experiment: the next fix gets tested against a mutated codebase, and any new symptom might be caused by your own residue rather than the original bug.

- When an attempt doesn't fix the bug, undo it completely — every file, every line, including "harmless" additions like logging you added as part of that theory
- Use version control to make this cheap: a clean starting commit or stash before debugging, `git diff` to audit what's currently changed, `git checkout`/`restore` to reset
- Before each new attempt, verify the working tree contains only (a) the pristine baseline and (b) deliberate instrumentation you're tracking on purpose
- If a failed attempt seems "worth keeping anyway," that's a separate proposal to make after the bug is fixed, not something to silently leave in the tree
- If behavior changes mid-session in a way you didn't predict, immediately ask: is this the bug, or debris from a previous attempt?
- The final fix must be re-verified on its own, applied alone to the clean baseline

**Red flags that you're about to violate this:**
- "That change didn't fix it, but I'll leave it since it's a reasonable improvement..."
- "No need to undo, the next change is in a different file..."
- "Reverting and re-editing wastes time; I'll just keep moving..."
- "The error is different now — interesting, let me chase that..." (without checking whether your own leftovers caused it)
- "I'll clean up the diff at the end..." (you won't remember what was load-bearing)
- Not knowing, at any given moment, exactly what's changed relative to baseline

### Shrink the Reproduction Before Debugging

Before deep-diving a bug that reproduces only through a large system, ALWAYS try to shrink the reproduction: strip away components, steps, and data until what remains is the smallest thing that still fails.

Every element you remove without losing the failure is an element proven innocent. Minimization is not prep work before the diagnosis; it is the diagnosis, running at high speed.

- Ask of the current repro: what can I delete? The UI (call the function directly), the network (use the captured payload), the database (use the literal failing row), auth, middleware, the other 95% of the input file
- Shrink the data too: cut the failing input in half repeatedly, keeping whichever half still fails; a 4MB "bad file" usually reduces to one bad line
- Keep the failure identical while shrinking — same error, same wrong value; if the symptom changes, you've cut something load-bearing, so put it back
- A fast repro changes everything downstream: aim for one command, seconds to run, so each later hypothesis costs seconds instead of minutes
- Know when to stop: if an hour of shrinking isn't converging, debug with what you have — minimization serves the investigation, not the other way around
- Keep the minimal repro when done; it's the regression test waiting to be committed

**Red flags that you're about to violate this:**
- "I'll just re-run the full flow each time to test theories..."
- "Too many layers are involved to isolate this; I'll read through all of them..."
- "Setting up a minimal case is overhead; let me start hypothesizing..."
- "The bug needs the whole app running..." (have you tried without?)
- Five debugging iterations done, each costing minutes of full-system setup
- Reading your eighth file while the failing function could be called directly with the failing input

### State a Hypothesis Before Each Fix

NEVER make a debugging edit without first stating, in one sentence, what you believe is wrong and what observation would prove or disprove it. "Let's try X and see" is not debugging; it's gambling with the codebase as chips.

An edit without a hypothesis produces an uninterpretable result: if it fails you've learned nothing, and if it "works" you don't know why — which means you don't know whether it actually fixed anything.

- Before each change, write the hypothesis in this shape: "I believe <specific cause> is producing <observed symptom> because <mechanism>. If true, <observable prediction>."
- Prefer testing the hypothesis with observation (a log, a debugger check, an isolated call) before testing it with a fix — confirmation is cheaper than modification
- A failed attempt must update your model: state what the failure eliminated before proposing the next hypothesis
- If you cannot form any hypothesis, that is a signal to gather more information (reproduce, instrument, read the trace), not a license to start trying things
- Rank competing hypotheses by evidence, not by which one has the easiest edit
- Words like "try," "maybe," "might help," and "see if" in your fix description mean the hypothesis step was skipped — go back and do it

**Red flags that you're about to violate this:**
- "Let me try changing this and see if it helps..."
- "It might be a caching thing; I'll disable the cache and check..."
- "Worth a shot to bump this dependency..."
- "I have a few ideas, I'll just go through them..." (ideas, not predictions)
- Choosing the next fix because it's easy to make, not because evidence points there
- Unable to say what you'd expect to observe if your current theory were true

### Suspect the Data and Config, Not Just Code

NEVER limit a bug hunt to source code. The program's behavior is a function of code *and* configuration *and* data *and* environment — and the last three are invisible in the repo, which is exactly why bugs hide there.

If the code you're reading plainly doesn't produce the observed behavior, stop re-reading it and start inspecting what it was given.

- Early in any investigation, enumerate the non-code suspects: environment variables actually loaded, config files and their override order, feature flags per environment, secrets and certificates (expiry!), the specific database rows involved, external API responses as received, file permissions, disk space, system clock
- Inspect actual values, not intended ones: print the loaded config at runtime, query the real rows, capture the real upstream response — the deploy docs say what *should* be set, the process knows what *is*
- Environment-specific failures (works in dev, fails in prod; works for everyone but one customer) are config/data bugs until proven otherwise — diff the environments and the accounts, don't re-read shared code that behaves differently in only one place
- When the bug is bad data: repair it, *and* find what produced it (a buggy migration, a race, an old code version) — and check for siblings, because corruption rarely hits exactly one row
- Never special-case known-bad data in application code as the fix; that hardcodes the corruption into the program permanently
- Code theories that require "perhaps under certain conditions" contortions are a signal to switch suspects: the simple explanation is that the inputs aren't what you think

**Red flags that you're about to violate this:**
- "Let me re-read this function again; the bug must be in here somewhere..."
- "Maybe under some rare condition this correct-looking code does the wrong thing..."
- "It only fails in production, so let me study the shared business logic..."
- "I'll add a special case for this one record..."
- Five files read, zero actual runtime values inspected
- Never having asked what config the failing process actually loaded

### Trace Bad Values to Their Source

NEVER fix a wrong value where it becomes visible. Trace it backwards to where it becomes wrong, and fix it there.

The display site is the last stop of a journey. Patching there beautifies one symptom while the corrupt value keeps flowing to every other consumer — and removes the only visible evidence that something is broken.

- Walk the dataflow upstream from the symptom: what produced this value, and what produced its inputs, until you find the first point where the data is wrong; that point is the bug
- Instrument the pipeline if reading isn't enough — print the value at each stage boundary and find the first stage whose output is bad
- Common birthplaces to check: parsing (string survived where a number was expected), arithmetic with absent operands, swapped arguments, a join or merge multiplying rows, unit or timezone mismatches at a boundary, a silent fallback returning a wrong default
- Before patching at the surface, ask: who else consumes this value? If the answer is "anyone at all," a display-site fix is leaving the bug live for all of them
- Cosmetic guards at the display layer (`?? 0`, `Math.max(0, x)`, `isNaN` checks) are acceptable only as explicitly-labeled defense in depth *after* the source is fixed — never as the fix itself
- Your explanation must name the birthplace: "the value goes wrong at <point> because <mechanism>," not "added handling for the bad value"

**Red flags that you're about to violate this:**
- "I'll add a fallback in the template so it displays cleanly..."
- "Clamping this to zero handles the negative case..."
- "Wherever it's coming from, the UI shouldn't show NaN..." (wherever?)
- "The other consumers probably aren't affected..."
- Fixing the symptom's location without being able to say where the value first went wrong
- A diff in the view layer for a bug whose wrongness is arithmetic

### Your Last Edit Is a Suspect, Not a Verdict

NEVER assume the most recent change did or didn't cause a new failure. Test it: remove the change, re-run, observe. The recent edit is always the prime suspect and never the convicted, until that experiment runs.

"It broke right after my edit" is correlation. The causation check costs one stash and one re-run.

- When a failure appears after a change: stash or revert the change (`git stash`, `git checkout -- <files>`), run the same reproduction, and note whether the failure persists
- Failure persists without the change → the change is innocent; restore it and look elsewhere, instead of "fixing" correct code
- Failure disappears without the change → the change is implicated; restore it and find which specific part is responsible, narrowing if it's large
- Do not acquit your edit just because the failing code is in a file you didn't touch — effects propagate through imports, shared state, ordering, and data; the stash test covers all of those at once, your intuition doesn't
- Do not convict your edit just because the timing matches — first-time-exercised paths, external services, and pre-existing bugs all produce post-edit failures
- State the experiment's result ("fails on clean baseline too" / "passes without my change") before proceeding either way

**Red flags that you're about to violate this:**
- "This broke right after my change, so my change must be the cause..."
- "The failure is in a module I never touched, so it's unrelated..."
- "I'll just adjust my recent edit until this goes away..."
- "This looks like a pre-existing issue, moving on..." (with the edit still applied)
- "Stashing and re-running is overhead; the cause is obvious..."
- Reasoning about what caused the failure for longer than the test would take to run
