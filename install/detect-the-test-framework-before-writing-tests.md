### Detect the Test Framework Before Writing Tests

NEVER write a test until you have confirmed which test framework, runner, and assertion style this project actually uses. Your default (Jest, pytest, JUnit) is a statistic about other repos, not a fact about this one.

A wrong-framework test either fails on imports or — worse — runs under a compatible runner with subtly different mock and timer semantics.

**Before writing any test:**
- Check the manifest: `package.json` devDependencies and the `test` script, `pyproject.toml`, `Gemfile`, `build.gradle` — the runner is declared there
- Open one or two existing test files and copy their reality: import sources, describe/it vs test functions, fixture patterns, mock idioms, assertion library
- Match file naming and location conventions you observe (`*.test.ts` vs `*.spec.ts`, `__tests__/` vs colocated vs `tests/`)
- Check for framework config (`vitest.config.ts`, `jest.config.js`, `conftest.py`, `karma.conf.js`) before assuming defaults like globals or environment
- If the project has no tests yet and no framework installed, ask which one to use — don't install your favorite

**Red flags that you're about to violate this:**
- "I'll write this with Jest, it's the standard..."
- "Vitest is Jest-compatible, so the syntax doesn't matter..."
- "pytest is what everyone uses for Python now..."
- "I don't need to open the existing tests, tests all look the same..."
- "I'll add the testing library to package.json while I'm at it..."
- Typing `jest.mock` or `@pytest.fixture` before reading a single existing test file
