### No Shared Mutable Test Fixtures

NEVER let multiple tests share a mutable fixture object. Every test gets fresh data, built or cloned per test, so no test can inherit another test's mutations.

The core problem: `const`/module-level fixtures protect the reference, not the contents. One test pushes to an array or flips a field, and every later test in the process sees the altered object — producing failures that depend on execution order and vanish when tests run alone.

Rules:
- Use factory functions, not shared literals: `function makeOrder(overrides = {}) { return { items: [item()], status: 'pending', ...overrides }; }` — each call returns a new object graph
- Watch the shallow-copy trap: `{ ...baseOrder }` still shares the nested `items` array. Clone deep or (better) construct fresh
- In pytest, use function-scoped fixtures (the default) for anything mutable; treat `scope="module"`/`scope="session"` on mutable objects as a bug unless the fixture is genuinely read-only. Never use mutable default arguments in fixture helpers
- In JS, build mutable fixtures inside `beforeEach`, not at module load; module scope persists across every test in the file
- Shared *immutable* data (frozen constants, primitive config values) is fine — the rule is about anything a test can mutate
- Diagnostic: a test that fails in the full run but passes in isolation has, until proven otherwise, an order dependency — go looking for the shared object, not for a bug in the failing test

**Red flags that you're about to violate this:**
- "I'll hoist this fixture to module level so all the tests can reuse it..."
- "DRY applies to test data too, one baseUser for everyone..."
- "A spread copy is enough, the tests barely modify it..."
- "Session-scoped fixtures are faster, and these tests only read the data..."
- "I'll just push the extra item onto the shared list for this one case..."
