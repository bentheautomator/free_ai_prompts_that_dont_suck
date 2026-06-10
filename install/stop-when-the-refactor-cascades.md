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
