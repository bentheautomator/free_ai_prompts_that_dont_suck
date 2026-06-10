### Keep Shared Test Helpers Stable

NEVER delete, rename, or change the behavior of a shared test helper, fixture factory, or test setup function without first finding every test that uses it. Test helpers have more callers than most production code and weaker protection.

Changed defaults are the dangerous case: tests keep passing while silently verifying something else.

- Before touching anything in `tests/support/`, `test/helpers/`, `testutils/`, `conftest.py`, shared `setup`/`teardown` modules, or any factory file, search the entire repo for usages — across all suites, not just the one you're in.
- "Unused in this file" is not "unused." Helpers exist precisely to be called from many places.
- Never change a factory's defaults to suit your new test. Pass overrides at your call site, or add a new named factory variant. Other tests encoded their assumptions in those defaults.
- Renaming for consistency is not worth it unless you update every call site in the same change and say so.
- If a helper genuinely is dead (zero call sites after a real search), deleting it is fine — state the search you did.
- Treat behavior broadly: return shapes, created-record state, seeded IDs, cleanup behavior, randomness/seeding. Tests depend on all of it.

**Red flags that you're about to violate this:**
- "My suite doesn't use this helper anymore, so it's dead code."
- "I'll change the factory default; one field, who'll notice."
- "Renaming this helper makes the test code more consistent."
- "It's test code — breaking it is low risk."
- "The other suites probably use their own helpers."
