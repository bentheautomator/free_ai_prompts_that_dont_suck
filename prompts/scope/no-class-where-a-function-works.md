---
title: No Class Where a Function Works
slug: no-class-where-a-function-works
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: medium
one_liner: "AI wrapping a simple function in a class with state and a builder"
---

# No Class Where a Function Works

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from delivering stateless logic as classes with constructors, instance state, and method ceremony.

**[Copy-paste ready version](../../install/no-class-where-a-function-works.md)** — just the instruction block, no explanation.

## The Problem

You ask for something that parses a duration string into seconds. You receive `DurationParser`, with an `__init__` that stores the input, a `parse()` method, a `result` property, sometimes a `DurationParserConfig` and a `.builder()` for good measure. Using it takes three lines — construct, call, extract — where one function call was the natural shape: `parse_duration("1h30m")`.

The AI does this because class-shaped code dominates "serious" examples in its training data, and a class with named methods looks more designed than a function. But a class earns its keep by managing state across calls or bundling genuinely coupled operations. Stateless logic in a class is pure ceremony with real costs: instances invite mutation and reuse questions that functions never raise (is the parser thread-safe? can I reuse it? does `parse()` twice double-append to `result`?), the API surface triples, and testing requires construction ritual. The object often smuggles in temporal coupling too — methods that only work if called in the right order, a bug class functions structurally cannot have.

A function that takes input and returns output is the maximally honest interface for a transformation. Wrapping it in a class doesn't add design; it adds questions.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Class Where a Function Works

Implement stateless logic as functions. NEVER wrap a transformation in a class just to give it a home, a name, or a "proper" shape.

The core problem: a class around stateless logic adds construction ritual, mutation and reuse questions, and potential call-order coupling, while a plain function answers all of those by construction.

- Input-to-output logic (parsing, formatting, validating, computing, converting) is a function, even when it's long or important
- A class is justified by state that must persist across calls, expensive setup reused by many calls (a connection, a compiled pattern set), or a group of operations sharing that state; absent those, no class
- Do not create config objects, builders, or fluent interfaces for callables with a handful of parameters; parameters are already the interface for that
- Do not store inputs or results on `self` so that a method pipeline can pass them; that converts function arguments into temporal coupling
- Several related functions can share a module/file; grouping is not a reason for a class
- Match the codebase: if the project structures similar logic as classes by strong convention, follow it and say you did; convention is a reason, aesthetics is not

**Red flags that you're about to violate this:**
- "I'll make this a class so it's properly encapsulated..."
- "A parser deserves to be its own object..."
- "Wrapping this in a class makes it easier to extend later..."
- "I'll add a config object so the constructor stays clean..."
- "Instance methods make the steps of the algorithm explicit..."
- "Object-oriented design is what they'd expect from production code..."

---

## Why It Works

1. **It states what earns a class.** The AI's trigger for classes is importance; replacing it with concrete justifications (cross-call state, shared expensive setup) gives a checkable test that parsing-a-string fails.

2. **It names temporal coupling as the smuggled bug.** Storing intermediate state on `self` feels organized; identifying it as call-order fragility that functions cannot have reframes the "organized" version as the riskier one.

3. **It answers the encapsulation reflex.** "Functions can share a module" gives the grouping urge a home that costs nothing, removing the last respectable reason for the wrapper.

4. **It defers to real conventions, not imagined ones.** Projects that genuinely structure logic as classes still get conformity, so the rule reads as "match reality," not "wage style war."

## Origin

A request for a function to compute shipping costs returned a `ShippingCostCalculator` with a builder, a config object, and a stateful `calculate()`/`get_result()` pair. A later caller invoked `get_result()` before `calculate()` and shipped `None` into an invoice total during a checkout edge case that testing missed because the test, naturally, called the methods in the documented order. The eventual fix replaced the class with an eleven-line function, deleting four files and the entire bug class with them.
