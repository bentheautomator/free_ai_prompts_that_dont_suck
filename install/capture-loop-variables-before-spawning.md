### Capture Loop Variables Before Spawning

When spawning any deferred work in a loop — tasks, threads, goroutines, callbacks, timers — ALWAYS bind the current iteration's values explicitly into the work. Never let deferred code read the loop variable later.

The closure runs after the loop has moved on; it sees the variable's final value, not the value you meant.

- Pass values as arguments, not captures: `executor.submit(deploy, cfg)` not `executor.submit(lambda: deploy(cfg))`; `setTimeout(fn, ms, value)` or a wrapper invoked with the value; default-argument pinning in Python (`lambda cfg=cfg: deploy(cfg)`) when a lambda is unavoidable.
- Go before 1.22 (and any codebase that must support it): shadow inside the loop, `s := s`, before `go func(){ ... }()`, or take the parameter form `go func(s Server){...}(s)`. Check the toolchain version before assuming the new semantics.
- JavaScript: `let`/`const` loop bindings are per-iteration; `var` is not. But a *mutable object* reused across iterations is the same bug regardless of binding — if you build-then-mutate a shared object, clone or construct fresh per iteration before handing it to deferred work.
- The rule covers all deferral, not just threads: event handlers registered in a loop, promise `.then` chains built in a loop, queued jobs whose payload references loop state.
- After writing any spawn-in-loop, verify with one question: "if every spawned body ran only after the loop completed, would it still be correct?" If not, a capture is wrong.
- Suspect this bug whenever N parallel results look identical or only the last item seems processed.

**Red flags that you're about to violate this:**
- "The lambda uses `cfg`, so it gets each iteration's config."
- "It worked when I tested with one item." (One iteration has no wrong value to capture.)
- "Go closures capture by value." (They capture the variable; pre-1.22 there's one per loop.)
- "I'll reuse this options object across iterations to avoid allocations."
- "The tasks start immediately, the loop variable won't have changed yet." (Starting isn't running.)
