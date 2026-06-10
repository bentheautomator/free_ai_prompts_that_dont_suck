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
