### Sandbox Test Side Effects

Tests must leave the machine exactly as they found it. NEVER write to real user directories, the repo working tree, shared paths, environment variables, or process globals without an automatic, failure-proof restore.

The core problem: leaked side effects outlive the test and corrupt later runs, parallel workers, other tests, and the developer's actual machine — producing failures whose cause is far away from their symptom.

Rules:
- Filesystem: use the framework's managed temp dirs — `tmp_path` (pytest), `t.TempDir()` (Go), `mkdtemp` in setup with teardown removal. Never write into the repo tree, `~`, or hardcoded `/tmp/myapp` paths (which collide under parallel runs)
- If the code under test has a hardwired real path, inject or patch the path for the test (`monkeypatch`, config override, env var the code respects) — don't let the test exercise the real location
- Environment variables: only through restoring mechanisms — `monkeypatch.setenv`, or save-and-restore in setup/teardown. A bare `process.env.X = ...` or `os.environ[...] = ...` in a test body is a leak in waiting
- Globals, singletons, module state, registered handlers, frozen time, network interceptors: every mutation needs a paired restore in teardown — `afterEach`, fixture finalizers, `jest.restoreAllMocks()`, `nock.cleanAll()`
- Cleanup goes in teardown hooks or fixtures, NEVER inline at the end of the test body — an assertion failure skips inline cleanup, so the test leaks exactly when it fails, which is when you least need extra chaos
- Verification: run the test twice in a row, and check `git status` is clean afterward. Second-run failure or new untracked files means you leaked

**Red flags that you're about to violate this:**
- "The test writes the file right here in the project, easy to inspect..."
- "I'll set the env var at the top of the test, it's only for this process..."
- "I added cleanup at the end of the test, after the assertions..."
- "The code always writes to ~/.appname, the test should match reality..."
- "/tmp/test-output is fine, it's temp by definition..."
