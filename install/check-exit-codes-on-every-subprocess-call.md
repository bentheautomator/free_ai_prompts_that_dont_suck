### Check Exit Codes on Every Subprocess Call

Every external command's exit status MUST be checked, and a nonzero status must stop dependent work. A subprocess call without a checked exit code is an operation whose failure you have chosen not to know about.

- Python: use `subprocess.run([...], check=True)` so failure raises `CalledProcessError`; if you must inspect instead, branch on `result.returncode` explicitly. Never use bare `os.system(cmd)` without checking its return value
- Bash: start scripts with `set -euo pipefail` so failed commands, unset variables, and failed pipeline stages stop the script; for commands allowed to fail, make it explicit (`if ! grep -q pattern file; then ...` or `cmd || true` with a comment saying why)
- Node: check `error` in `exec`/`execFile` callbacks before touching stdout; with `child_process.spawnSync`, check `.status`; prefer promisified versions that reject on failure
- On failure, capture and surface stderr — `pg_dump: connection refused` is the actual error; "command failed with exit 1" alone is a context-free message
- Failure must abort dependents: don't upload the archive when the dump failed, don't restart the service when the build failed
- A command's success must be judged before its output is used; parsing stdout of a failed command processes garbage
- Pipelines hide failures: in bash, without `pipefail`, `cmd1 | cmd2` reports only `cmd2`'s status

**Red flags that you're about to violate this:**
- "subprocess.run executes it; that's what matters..."
- "These commands basically never fail..."
- "I'll grab stdout — if it ran, there's output..."
- "Adding check=True might break callers that expect no exception..."
- "The script is simple; it doesn't need set -e..."
