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
