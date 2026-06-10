### No Circular Imports Between Modules

NEVER add an import that creates a dependency cycle between modules or packages. Before importing from module B while editing module A, check whether B (directly or transitively) already imports A.

Cycles fuse two modules into one untestable blob, and in Python/JavaScript they cause load-order bugs that pass locally and fail in production.

- Before adding a cross-module import, grep the target module for imports of the module you are editing; if any exist, stop and restructure instead
- If both modules need the same type or helper, move it DOWN into a module both can depend on (`shared`, `core`, `types`), never sideways
- If A needs to trigger behavior in B and B already depends on A, invert it: B passes a callback, B subscribes to an event A emits, or A exposes an interface that B implements
- Do not "fix" a cycle with a lazy import, an import inside a function body, a deferred `require()`, or a type-only import that hides a real runtime dependency; these conceal the cycle, they don't remove it
- In Go or other languages where the compiler rejects cycles, do not merge the two packages to make the error go away; restructure the dependency instead

**Red flags that you're about to violate this:**
- "The type I need is right there in billing, one import won't hurt..."
- "I'll just import it inside the function so it resolves at call time..."
- "It's only a type import, that doesn't really count as a dependency..."
- "The compiler complains about the cycle, so I'll combine the packages..."
- "Tests pass, so the import order must be fine..."
