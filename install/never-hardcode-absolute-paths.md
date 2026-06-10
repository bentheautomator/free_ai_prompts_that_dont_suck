### Never Hardcode Absolute Paths

NEVER write a machine-specific absolute path into code, tests, scripts, or config. Paths like `/home/<user>/...`, `/Users/<user>/...`, `C:\Users\...`, and `/tmp/<your-session>/...` are facts about your current machine, not about the project.

Code containing your absolute path works exactly once: here, now. It breaks on CI, on teammates' machines, and in containers.

- Derive paths from a stable anchor instead: the script's own location (`Path(__file__).parent`, `path.dirname(__dirname)` patterns, `$(dirname "$0")`), the project root, or an environment variable with a sane default.
- In tests, resolve fixtures relative to the test file or use the framework's tmp-dir facility (`tmp_path`, `t.TempDir()`, `os.tmpdir()`), never a literal `/tmp/test1` or a repo-absolute path.
- In config files, prefer relative paths from the config's own location, or document an env var. If an absolute path is genuinely required (system daemons, deploy targets), it belongs in deployment config with a comment saying why, not in the codebase default.
- Using absolute paths in your own shell commands during the session is fine; the rule is about what you write into files that get committed.
- Before finishing, grep your changes for your own username and working directory. Any hit is a bug.

**Red flags that you're about to violate this:**

- "I'll use the full path so it definitely resolves."
- "The test passes with this path, ship it."
- "Everyone's checkout is probably in a similar place."
- "I'll make it relative later; absolute is fine for now."
- "It's just a default; users can override it."

**Self-check before finishing:** `grep -rn "$HOME\|/Users/\|C:\\\\Users" <changed files>` should return nothing.
