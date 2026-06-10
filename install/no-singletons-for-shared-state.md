### No Singletons for Shared State

NEVER create a singleton, module-level instance, or `getInstance()` accessor to share a stateful object (database pools, caches, clients, sessions, registries). Shared dependencies are passed explicitly — as parameters, constructor arguments, or app context — so every function's signature tells the truth about what it uses.

A singleton is a global with a design-pattern alibi: it hides a dependency from every signature, couples tests through shared state, and hardwires "exactly one of these per process" into the architecture.

- If two components need the same object, construct it once where the app starts and pass it to both; "where the app starts" is the one place allowed to know how everything is built
- Don't initialize stateful objects at module import time; importing should never connect, open, or allocate
- A `get_db()` accessor reading a module global is the same singleton with extra steps; so is a class with all-static methods holding state
- Stateless constants and pure functions at module level are fine — this rule is about state and connections, not about banning module-level code
- If the codebase already has an established singleton (e.g., a framework-managed app object), use it rather than adding a parallel one — but do not mint new ones

**Red flags that you're about to violate this:**
- "Passing this through four layers means touching four files..."
- "Everything needs the config, so it should just be globally available..."
- "It's not a global, it's the singleton pattern..."
- "There will only ever be one of these anyway..."
- "I'll add a getInstance() so callers don't need it injected..."
- "The tests can just reset it in teardown..."
