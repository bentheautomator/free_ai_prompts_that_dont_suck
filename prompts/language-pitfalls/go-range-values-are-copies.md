---
title: Go Range Values Are Copies
slug: go-range-values-are-copies
category: language-pitfalls
tags: [universal, go]
works_with: all
severity: high
one_liner: "Stops mutating the range copy and aliasing the loop variable in Go"
---

# Go Range Values Are Copies

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `for _, item := range items { item.Done = true }` mutating a copy while the slice stays untouched — and `&item` collecting pointers to the wrong thing.

**[Copy-paste ready version](../../install/go-range-values-are-copies.md)** — just the instruction block, no explanation.

## The Problem

`for _, item := range items` gives you a *copy* of each element. Write `item.Done = true` and you've updated the copy, which is discarded at the end of the iteration; the slice is exactly as un-done as before. The loop runs, no error occurs, debug prints inside the loop even show the mutated value — and the data structure is unchanged. For a model porting from Python (`for item in items:` yields references) or Java (references again), this is an invisible semantic swap: identical-looking code, opposite behavior.

The pointer cousin: taking `&item` to collect or store elements gives you the address of the loop variable, not the element. Before Go 1.22, the variable is also *reused* across iterations, so every collected pointer ends up pointing at the final element — N pointers, one value. Go 1.22+ gives each iteration a fresh variable, which fixes the aliasing flavor but does nothing for the mutate-a-copy flavor, and generated code rarely gets to assume a minimum toolchain.

Assistants produce both shapes constantly because value-semantics ranges are unusual among mainstream languages, and the broken code is byte-for-byte plausible. They also "fix" one flavor while introducing the other — switching to index access for mutation, then taking `&items[i]` of a slice that's about to be appended to (and reallocated), which is its own dangling-pointer story.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Go Range Values Are Copies

NEVER mutate the value variable of a Go `range` loop expecting the collection to change — it is a copy. Mutations must go through the index or a pointer to the element.

- Wrong: `for _, o := range orders { o.Status = "done" }` — modifies copies; `orders` is unchanged. Right: `for i := range orders { orders[i].Status = "done" }`.
- Slices of pointers (`[]*Order`) are the exception: the copied value is a pointer to the shared struct, so `o.Status = "done"` works. Know which one you're holding before choosing the pattern.
- Collecting pointers: `out = append(out, &item)` aliases the loop variable. Pre-Go-1.22 every pointer ends up at the last element; even on 1.22+, prefer `&items[i]` or copy explicitly (`item := item` pre-1.22) so the code doesn't depend on toolchain version.
- `&items[i]` is only stable while the backing array isn't reallocated — don't take element pointers from a slice you're still appending to.
- Maps: `range` over a map yields copied values too, and map values aren't addressable; to mutate, write the whole value back (`m[k] = v`) or store pointers in the map.
- Large structs: the per-iteration copy is also a performance cost; `for i := range` avoids it.
- Don't assume Go 1.22 loop-variable semantics fixed all of this: it fixed variable reuse across iterations, not the fact that the value is a copy.

**Red flags that you're about to violate this:**

- "I set the field inside the loop, so the slice is updated."
- "The print statement shows the new value, the mutation worked." (On the copy.)
- "`&item` gives me a pointer to the element."
- "Go 1.22 fixed the range variable problem, this pattern is safe now."
- "It's the same loop I'd write in Python."

---

## Why It Works

1. **It names the silent success.** No panic, no vet warning, even debug output looks right — telling the model why its usual verification signals are worthless here forces it to use the structural rule instead.
2. **It splits the two flavors explicitly.** Mutate-a-copy and alias-the-variable have different fixes; models told only one tend to repair into the other, so the rule covers the pair plus the `&items[i]` reallocation caveat that the second fix introduces.
3. **It corrects the 1.22 over-generalization.** "The loop variable thing was fixed" is true for capture, false for copies; drawing that line prevents the rule being dismissed as obsolete.
4. **It conditions the pattern on the element type.** `[]T` vs `[]*T` determines whether the "wrong" code is actually right; stating that check keeps the model from cargo-culting index access where it isn't needed.

## Origin

A billing reconciler looped `for _, inv := range invoices { inv.Reconciled = true }` and then persisted `invoices`. Every invoice saved with `Reconciled: false`, so the next run picked them all up again — the job re-reconciled the full history nightly, and the duplicate-detection downstream absorbed the load quietly until a month-end run blew its time budget. The log line inside the loop printed `reconciled=true` for every invoice, which is why three engineers cleared the function as obviously correct.
