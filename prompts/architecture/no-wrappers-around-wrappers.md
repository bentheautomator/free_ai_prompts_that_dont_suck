---
title: No Wrappers Around Wrappers
slug: no-wrappers-around-wrappers
category: architecture
tags: [universal, architecture, indirection]
works_with: all
severity: medium
one_liner: "A forwarding layer stacked on a layer that was already just forwarding"
---

# No Wrappers Around Wrappers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding another pass-through layer on top of an existing one, so that calling a function means tunneling through four files that each add nothing.

**[Copy-paste ready version](../../install/no-wrappers-around-wrappers.md)** — just the instruction block, no explanation.

## The Problem

The codebase has `http_client.py`, which wraps the HTTP library to add auth headers. The AI needs to call an API, and instead of using the client, it writes `ApiService`, which wraps `http_client`, and then `UserApiService`, which wraps `ApiService`. Each layer renames the method, reshuffles the arguments, and forwards. None of them makes a decision. "Go to definition" is now spelunking: four jumps to find the line that actually does something.

The AI builds these because wrapping *looks like* architecture. A class per layer, clean names, small files — every individual wrapper resembles good design. The tell is what's inside: if a layer only renames, reorders, and forwards, it isn't a layer, it's a toll booth. And every toll booth has to be updated when the real signature changes, which is how a one-parameter addition becomes a five-file diff.

There's also a compounding failure: the AI frequently can't see that the existing thing is *already* a wrapper. It treats `http_client` as "the low-level thing" that obviously needs wrapping, the way the HTTP library was once "the low-level thing." Each generation of code wraps the last, sediment over sediment.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Wrappers Around Wrappers

NEVER add a layer that only forwards to another layer. A wrapper is justified when it makes a decision, enforces a policy, or changes the abstraction level — not when it renames methods and passes arguments through.

Pass-through layers add a file to every navigation, a hop to every stack trace, and a mandatory edit to every signature change, in exchange for nothing.

- Before wrapping something, check whether it is itself already a wrapper (a thin module over a library or client); if so, the strong default is to extend or use the existing wrapper, not stack a new one on it
- A layer earns its existence by doing at least one of: enforcing policy (retries, auth, limits), translating between abstraction levels (HTTP to domain objects), or isolating a third-party API behind a project-owned seam. "Nicer name for our codebase" is not on the list
- If you need one convenience default, add a function or parameter to the existing layer instead of a class around it
- Never wrap to shorten a call: `get_user(id)` forwarding to `client.get(f"/users/{id}")` is a one-line saving that costs a permanent file
- When you find yourself writing a method whose body is a single call with the same arguments in a different order, stop — delete the method and call the target directly

**Red flags that you're about to violate this:**
- "I'll make a service class so the calls look cleaner..."
- "Wrapping it gives us a place to add logic later..."
- "Every other client has a wrapper, this one should too..."
- "The existing client's method names don't match our naming style..."
- "It's only a thin layer, it doesn't really count as indirection..."

---

## Why It Works

1. **It defines what a layer must buy.** "Policy, translation, or seam" is a concrete admission test; without it, every wrapper passes review because every wrapper looks tidy.

2. **It forces the is-it-already-a-wrapper check.** The sedimentation failure comes from not knowing the existing layer's role; one look inside the thing being wrapped usually settles the question.

3. **It redirects energy to the existing layer.** Most wrapper urges are really "the current layer is missing one convenience" — adding it there improves one file instead of creating a fourth.

4. **It gives a syntactic tripwire.** "Body is a single forwarding call" is detectable while writing, which catches the violation at the moment of creation rather than in review.

## Origin

A team counted the layers between a button click and the actual network request in their app: seven, of which five contained no logic — each added in a different quarter, each wrapping "the messy thing below it." Adding a timeout parameter to requests required editing six files and was estimated as a full day. The eventual flattening deleted 1,100 lines and changed observable behavior in no way whatsoever, which was both the point and the indictment.
