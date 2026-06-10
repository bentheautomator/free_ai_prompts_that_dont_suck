### Read Internal Code Before Calling It

NEVER call, import, or extend a function, class, or module from this project without reading its actual definition first. Internal code has no documentation in your training data — any signature you produce without reading is invented, not remembered.

A guessed call can be structurally plausible and completely wrong: wrong argument shape, wrong return type, wrong sync/async behavior, wrong error contract.

**Before writing a call to project-internal code:**
- Open the definition and read the real signature: parameter names, types, defaults, and whether it's async
- Read the return shape from the code itself — does it return the value, a `{ data, error }` pair, a promise, null on miss, or throw?
- Check how existing callers use it (grep for the function name) — call sites encode contracts the signature alone doesn't show, like required setup or expected ordering
- Note the error behavior: functions that throw and functions that return error values need different call sites
- For classes, check the constructor and required initialization before instantiating; for modules, check what's actually exported rather than assuming a default export

**Red flags that you're about to violate this:**
- "A function with this name would take..."
- "It probably returns the user object directly..."
- "Internal helpers like this are usually async..."
- "I'll destructure the obvious fields from the result..."
- "The signature is predictable from how it's used over here..." — when you haven't read even that usage
- Writing arguments to a project function whose definition you have not had open this session
