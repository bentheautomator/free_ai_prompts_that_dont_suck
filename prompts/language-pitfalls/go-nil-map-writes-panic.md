---
title: Go Nil Map Writes Panic
slug: go-nil-map-writes-panic
category: language-pitfalls
tags: [universal, go]
works_with: all
severity: high
one_liner: "Stops writes to nil Go maps panicking after reads worked fine"
---

# Go Nil Map Writes Panic

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `var m map[string]int` followed by `m[k] = v` — reads from nil maps work, writes panic at runtime.

**[Copy-paste ready version](../../install/go-nil-map-writes-panic.md)** — just the instruction block, no explanation.

## The Problem

Go's nil map has asymmetric semantics designed to maximize the time between bug and detonation. Reading from a nil map is fine: `m[k]` returns the zero value, `len(m)` is 0, `range m` iterates zero times. Writing panics: `assignment to entry in nil map`, at runtime, with no compile-time warning. So `var m map[string]int` (or a struct with an uninitialized map field, or a map field that JSON unmarshaling left nil because the key was absent) behaves perfectly through every read path and crashes on the first code path that writes.

The struct-field version is the one that ships: `type Cache struct { entries map[string]Entry }` works for every constructor call site that happens to populate it, then someone constructs the struct with a literal that skips the field, all the lookups still return zero values, and a write three packages away panics in production. Slices, by contrast, forgive this — `append` to a nil slice works — which trains both humans and models that nil collections are writable.

Assistants generate `var m map[T]U` declarations because the declaration is idiomatic-looking and *is* idiomatic for read-only use; the model fails to track whether a write happens downstream. It also writes struct literals without initializing map fields because the compiler doesn't complain.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Go Nil Map Writes Panic

NEVER write to a Go map without ensuring it was initialized. Nil maps read fine (`m[k]` gives the zero value, `len` is 0, `range` is empty) but any write panics at runtime — so the bug hides behind every read-only code path.

- Initialize at declaration: `m := map[string]int{}` or `make(map[string]int)`, not `var m map[string]int`, unless the map is provably never written.
- Structs with map fields: initialize in a constructor (`func NewCache() *Cache { return &Cache{entries: make(map[string]Entry)} }`) and route creation through it. A struct literal that omits a map field leaves it nil.
- Deserialization: `json.Unmarshal` leaves a map field nil when the key is absent from the input. If code writes to that map afterward, nil-check and `make` it first.
- Lazy-init guard where construction can't be controlled: `if m == nil { m = make(...) }` before the write — but prefer fixing the constructor.
- Nested maps: `m[a][b] = v` needs the inner map to exist. Initialize on first use: `if m[a] == nil { m[a] = make(map[K]V) }`.
- Do NOT port this caution to slices and conclude `append` needs a non-nil slice — `append(nilSlice, x)` is correct, idiomatic Go. The asymmetry is the trap: slices forgive, maps don't.
- Deleting from a nil map is a no-op (legal); only writes panic. Don't add nil-checks to read/delete paths that don't need them.

**Red flags that you're about to violate this:**

- "`var m map[string]int` is the cleaner way to declare it."
- "All the tests pass, the map is clearly initialized." (Tests may only exercise reads.)
- "The struct literal sets the fields that matter."
- "Unmarshal will populate the map." (Only if the key is present.)
- "It works like a nil slice — Go zero values are usable."

---

## Why It Works

1. **It explains the asymmetry that hides the bug.** "Reads work, writes panic" is why testing and review miss it; once the model knows nil maps pass read-path tests, "tests pass" stops counting as evidence.
2. **It severs the slice analogy.** `append`-to-nil works, and that's the prior the model applies to maps; explicitly contrasting the two collections removes the false equivalence in both directions.
3. **It targets the two realistic entry points.** Bare `var` declarations and skipped struct/JSON fields are where nil maps actually come from; rules tied to those sites fire at the right moment.
4. **It bounds the paranoia.** Permitting nil-map reads and deletes prevents the overcorrection where every map access grows a guard and the rule gets deleted as noise.

## Origin

A metrics aggregator defined `type bucket struct { counts map[string]int64 }` with a constructor that initialized the map — and one hot path that, under a rare branch, built the struct with a bare literal to "skip the allocation." Every read worked. Weeks later a new label was introduced that hit the rare branch first, the first write panicked, and the aggregator crash-looped during the exact traffic spike it existed to measure.
