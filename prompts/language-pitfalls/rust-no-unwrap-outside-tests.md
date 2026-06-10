---
title: Rust No Unwrap Outside Tests
slug: rust-no-unwrap-outside-tests
category: language-pitfalls
tags: [universal, rust]
works_with: all
severity: high
one_liner: "Stops unwrap and expect from turning recoverable errors into prod panics"
---

# Rust No Unwrap Outside Tests

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `.unwrap()` scaffolding from shipping, where every recoverable error becomes a panic that kills the thread or the process.

**[Copy-paste ready version](../../install/rust-no-unwrap-outside-tests.md)** — just the instruction block, no explanation.

## The Problem

Rust forces you to acknowledge every `Result` and `Option`, and `.unwrap()` is the acknowledgment that says "crash if I'm wrong." In generated code it says something else: "I didn't want to deal with the error type right now." The model writes `let config = fs::read_to_string(path).unwrap()`, `let port: u16 = s.parse().unwrap()`, `let val = map.get(&key).unwrap()` — and each one converts a routine, recoverable condition (file missing, bad input, absent key) into a panic. In a server, that's a killed worker thread or an aborted process; in a library, it's *your caller's* process, crashed by a failure mode your function signature promised nothing about.

The deeper cost is that unwraps poison incrementally. One unwrap in a call chain means the function returns `T` instead of `Result<T, E>`, so the callers don't propagate errors either, and converting the code to proper handling later means re-plumbing signatures through every layer. The five-second shortcut becomes a refactor nobody schedules.

Assistants emit unwrap because example code, docs, and tutorial snippets — the bulk of Rust training data — unwrap everything to keep examples short, with a disclaimer the model didn't ingest as load-bearing. Generated Rust therefore looks like example code wearing a production badge.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Rust No Unwrap Outside Tests

NEVER use `.unwrap()` or `.expect()` on a `Result`/`Option` in production code paths to avoid handling the error. Unwrap converts recoverable failures into panics; in a server it kills the thread, in a library it crashes the caller.

- Propagate by default: return `Result` and use `?`. If the error types don't line up, that's what `From` impls, `map_err`, or an error crate (`thiserror` for libraries, `anyhow` for binaries) are for — not a reason to unwrap.
- Wrong: `let n: u32 = input.parse().unwrap()` on external input. Right: `let n: u32 = input.parse().map_err(|e| ...)?` or match and handle.
- `Option` with a sensible fallback: `unwrap_or`, `unwrap_or_else`, `unwrap_or_default`, or `ok_or(...)?` to convert to a `Result`.
- Genuine invariants — cases that are provably impossible — may use `.expect("why this cannot fail: ...")` with the invariant stated in the message. Bare `.unwrap()` carries no such proof and should be treated as a TODO that escaped.
- Acceptable unwrap zones: tests, examples, build scripts, one-off CLI prototypes explicitly labeled as such, and constants checked at startup (`Regex::new(KNOWN_PATTERN)` — though `LazyLock` + `expect` with a message is still better).
- Do not bypass the rule with equivalents: indexing (`map[&key]`, `slice[i]`) and `panic!`/`todo!`/`unimplemented!` on reachable paths are unwraps in disguise.
- Don't swing to the opposite failure: silently swallowing errors (`let _ = ...`, `.ok()` discarding a Result that matters) is worse than panicking. The goal is *handled*, not *quiet*.

**Red flags that you're about to violate this:**

- "I'll unwrap for now and add error handling later."
- "This can't fail in practice." (Then write `expect` with the proof, and check the proof.)
- "Adding a Result return type means changing five callers."
- "The examples in the crate docs all use unwrap."
- "It's just a parse of a value we control." (Config files and env vars are external input.)
- "A panic is fine, the orchestrator will restart it."

---

## Why It Works

1. **It reframes unwrap as a deferred decision, not a small one.** The model treats unwrap as low-cost; naming the signature-poisoning effect (callers can't propagate what you panicked on) prices it correctly.
2. **It separates invariants from laziness with a syntactic tell.** `expect` with a stated invariant is auditable; bare `unwrap` is declared to *mean* "unhandled," which makes violations findable by grep and CI (`clippy::unwrap_used`).
3. **It closes the disguise loopholes.** Indexing and `todo!` are how the model complies with the letter while panicking anyway; enumerating them keeps the rule about behavior, not spelling.
4. **It guards the overcorrection.** Models told "don't panic" start discarding errors; stating that swallowing is worse keeps the correction pointed at propagation.

## Origin

An ingest service parsed a timestamp header with `.unwrap()`, on the reasoning that the upstream service always sent one. A partner integration eventually didn't. Each malformed request panicked its worker; the async runtime kept restarting them, so the service stayed "up" while throughput collapsed under the panic-restart churn — visible only as a latency cliff and a log volume bill. The eventual diff replaced one unwrap with a 400 response and a counter, which is what the function should have meant from the start.
