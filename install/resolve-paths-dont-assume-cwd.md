### Resolve Paths, Don't Assume the CWD

NEVER write code or run commands whose correctness depends on an unverified current working directory. Anchor every relative path to something stable.

The cwd is set by the caller, not by you, and every invoker — cron, CI, a user in a subdirectory — sets it differently.

- In scripts, resolve relative to the script's own location: `SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)` in bash, `Path(__file__).resolve().parent` in Python, `__dirname`/`import.meta.url` in Node. Then build paths from that anchor.
- In application code, resolve relative to an explicit root passed in via argument, env var, or config — not whatever `process.cwd()` happens to be, unless cwd-relative is the documented contract (CLI tools acting on the user's directory).
- In your own shell work, prefer absolute paths in commands. Don't carry cwd assumptions across multiple commands; a `cd` earlier in the session is state you'll forget. Verify with `pwd` if anything depends on it.
- `cd` inside scripts changes state for everything after it; if you must, use a subshell `(cd dir && ...)` so the change can't leak.
- Files you create land relative to the cwd too: a "local" output file written from the wrong directory is a stray artifact in a random location.
- Before shipping a script, ask: what happens if this runs from `/`? If the answer is "breaks" or "writes somewhere weird," anchor the paths.

**Red flags that you're about to violate this:**

- "It works when I run it from the repo root, and that's how people run things."
- "I cd'd earlier, so relative paths are fine from here."
- "The config file is at ./config.yaml." (Relative to what, exactly?)
- "Cron will run it the same way I did."
- "I'll fix the paths if someone hits a problem."
