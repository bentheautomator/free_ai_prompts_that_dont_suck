### Construct Dependencies at the Composition Root

NEVER construct stateful or configurable dependencies — database connections, HTTP clients, repositories, service objects, queue producers — inside business logic. Construction happens at the composition root (main, app startup, the DI container, the request factory); everything below receives its dependencies as constructor or function parameters.

Code that builds its own dependencies has decided, unilaterally and invisibly, which implementation, which config, and which lifecycle the whole application gets.

- A class that needs a repository takes it in its constructor; the place that builds the class supplies it. If that means a parameter ripples up a level or two, that ripple is the wiring becoming visible — it's the feature, not the cost
- Find the codebase's existing composition root before inventing one: a `main()`, an app factory, a DI container, framework startup hooks. Add new wiring there, in the established style
- Don't read config (env vars, settings) deep in the call stack to build things; config is read at the root, dependencies are built from it once, and objects receive them
- Value objects and pure data (a dataclass, a datetime, a Decimal) are constructed wherever needed — this rule is about dependencies with identity, state, configuration, or I/O
- Don't overcorrect into a framework: passing parameters IS dependency injection; introducing a DI container the codebase doesn't have is a rival-pattern violation, not compliance
- If you're three layers deep and the dependency isn't available, the fix is adding it to the constructor chain — not `new`, not a global, not a `get_client()` that hides the `new`

**Red flags that you're about to violate this:**
- "I'll just create the client here, it's only used in this function..."
- "Threading it through two constructors is too much plumbing..."
- "Reading the env var here is simpler than passing config down..."
- "A fresh connection per call is fine, it's not hot code..."
- "I'll add a helper that constructs it on demand..."
