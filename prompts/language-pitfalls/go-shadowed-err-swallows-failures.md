---
title: Go Shadowed err Swallows Failures
slug: go-shadowed-err-swallows-failures
category: language-pitfalls
tags: [universal, go]
works_with: all
severity: high
one_liner: "Stops := inside blocks from shadowing err so failures check a stale variable"
---

# Go Shadowed err Swallows Failures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `:=` inside an inner scope from creating a *new* `err` that gets checked while the outer `err` — the one callers see — stays nil.

**[Copy-paste ready version](../../install/go-shadowed-err-swallows-failures.md)** — just the instruction block, no explanation.

## The Problem

`:=` declares new variables in the current scope. Use it inside an `if`, `for`, or any nested block when an `err` already exists outside, and you've made a second `err` that shadows the first. The classic shape: a function declares `var result T; var err error`, then inside a branch writes `result, err := fetch()` — new `result`, new `err`, both confined to the block. The inner check `if err != nil` passes or fails correctly *inside*, but the outer `result` is never assigned and the outer `err` stays nil, so the function returns a zero-valued result and no error. `go vet` doesn't flag it by default; the code compiles; reviewers read straight past it because the error *is* checked — just the wrong one.

A related shape hits named return values: `func f() (err error)` with an inner `err := ...` means the deferred `if err != nil` cleanup at the end inspects the unshadowed nil, and the failure escapes the cleanup path entirely.

Assistants generate this constantly because `x, err := call()` is the single most reinforced pattern in Go training data — the model emits `:=` wherever a call returns an error, without checking whether `err` already exists in an enclosing scope. Refactors that wrap existing calls in a new `if` or `for` block convert correct `=` assignments into shadowing `:=` ones.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It separates "checked" from "checked the right one".** The model (and reviewers) verify an `if err != nil` exists; the rule retargets attention to *which* `err` that is, which is the actual bug.
2. **It flags block-wrapping as the dangerous edit.** Most shadowing isn't written, it's created by refactors that add scope around existing `:=`; naming that edit makes the model re-audit at the right moment.
3. **It promotes the structure that makes the bug impossible.** Early-return error handling eliminates long-lived outer `err` variables, removing the precondition rather than policing the symptom.
4. **It points at mechanical enforcement.** The shadow analyzer turns a subtle review problem into a CI failure, which outlives any prompt.

## Origin

A storage client had `var resp *Response; var err error` followed by a retry loop containing `resp, err := s.do(req)`. Inside the loop, errors were checked and retried correctly. After exhausting retries the function returned the *outer* pair: nil response, nil error. The caller treated nil-error-nil-response as success-with-no-content and acknowledged messages it had never durably written. The data gap was found during an audit weeks later; the diff that fixed it was two characters.
