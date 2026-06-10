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
