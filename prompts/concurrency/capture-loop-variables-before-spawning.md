---
title: Capture Loop Variables Before Spawning
slug: capture-loop-variables-before-spawning
category: concurrency
tags: [universal, concurrency, closures]
works_with: all
severity: high
one_liner: "Stops spawned closures from all seeing the loop variable's final value"
---

# Capture Loop Variables Before Spawning

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from spawning tasks, threads, or callbacks inside a loop that close over the loop variable itself, so every one of them runs with the last iteration's value.

**[Copy-paste ready version](../../install/capture-loop-variables-before-spawning.md)** — just the instruction block, no explanation.

## The Problem

Spawn a worker per item in a loop, and the closure captures the loop *variable*, not the loop *value*. By the time the workers actually run — after the loop finished, because spawning is fast and running is later — the variable holds the final item. Ten workers all process item ten. In Python, `for cfg in configs: executor.submit(lambda: deploy(cfg))` deploys the last config ten times. In pre-2022 Go, `for _, s := range servers { go restart(s) }` restarts one server repeatedly (fixed in Go 1.22's per-iteration semantics — unless you're on an older toolchain, which plenty of production code is). JavaScript's `let` saved the `for` loop, but `var`, shared mutable objects reused across iterations, and "build the object, queue the callback, then mutate the object for the next iteration" all still bite.

AI assistants produce this because the closure looks like it obviously means "this iteration's value" — that's what it means in the synchronous version, where the body runs before the variable changes. The deferral is what breaks it, and deferral is invisible at the spawn site. Worse, results can *look* plausible: ten tasks ran, ten log lines appeared, the dashboard shows ten completions. They just all did the same one thing.

The rule is mechanical: bind the value into the task explicitly, before the variable can move on.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **Pass-as-argument moves the binding from closure semantics (subtle, per-language, version-dependent) to function-call semantics (evaluated now, everywhere, always)** — it's correct without requiring the AI to model any capture rules.
2. **The "runs after the loop completes" thought experiment is a deterministic detector:** it converts a timing-dependent bug into a question answerable from the code alone.
3. **Covering mutable-object reuse closes the modern escape hatch,** where the binding is per-iteration but the data it points to isn't.
4. **The identical-results symptom gives a diagnostic hook,** so the bug gets recognized from its signature instead of re-debugged from scratch.

## Origin

A rollout script looped over twelve regions, spawning a thread per region to apply that region's config. Every thread captured the loop variable; all twelve applied the *last* region's config, including its DNS endpoints. Eleven regions came up healthy, green dashboards everywhere, all serving traffic pointed at region twelve. The incident took ninety minutes to even look like a code bug, because twelve threads had visibly run and twelve success messages had printed — each one truthfully reporting the same wrong deployment.
