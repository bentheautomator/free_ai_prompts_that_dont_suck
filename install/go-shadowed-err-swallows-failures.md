### Go Shadowed err Swallows Failures

NEVER use `:=` in an inner scope when it re-declares a variable (especially `err` or a result) that an enclosing scope declares and later uses. The inner block gets fresh variables; the outer ones silently keep their old values — typically a nil `err` and a zero result.

- Wrong: outer `var data []byte; var err error`, then inside a branch `data, err := load(path)` — outer `data`/`err` untouched; function returns empty data, nil error. Right: `data, err = load(path)` (plain `=`).
- When a call returns one new variable plus an existing `err`, `:=` only works without shadowing if at least one variable on the left is new *and you're in the same scope*. Inside a nested block, declare the new variable first (`var n int`) and use `=`, or restructure.
- The safest structure avoids the situation: handle errors immediately and return early (`x, err := call(); if err != nil { return ... }`) instead of accumulating into long-lived outer `err`/result variables that inner blocks must assign.
- Named return values + `defer` that reads `err`: any inner `err :=` disconnects the deferred check from the actual failure. Inside such functions, be strict about `=` vs `:=`.
- After writing or moving code into a new `if`/`for`/`switch` block, re-check every `:=` inside it against enclosing declarations — wrapping code in a block is how correct `=` becomes shadowing `:=`.
- Enable shadow analysis in CI where practical: `go vet -vettool` with the `shadow` analyzer catches most of these mechanically.

**Red flags that you're about to violate this:**

- "`x, err := call()` is the idiomatic form, always."
- "The error is checked right below the call, this is handled."
- "I'm just wrapping these lines in an if-block, nothing changes."
- "The compiler would complain if I redeclared a variable." (Not across scopes — that's shadowing, and it's legal.)
- "The deferred cleanup will catch any error before returning."
