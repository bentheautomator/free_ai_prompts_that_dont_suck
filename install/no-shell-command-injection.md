### Never Build Shell Commands From User Input

NEVER interpolate user-controlled data into a shell command string. ALWAYS pass arguments as an array to an API that does not invoke a shell.

A command string plus user input is remote code execution waiting for one semicolon, backtick, or `$()`.

- Python: use `subprocess.run([...], shell=False)` with a list of arguments. Do not use `shell=True`, `os.system`, or `os.popen` with any dynamic content.
- Node: use `execFile` or `spawn` with an args array. Do not use `child_process.exec` or backtick-built command strings with dynamic content.
- Go/Rust/Java: `exec.Command(name, args...)` and equivalents already separate arguments; do not wrap commands in `sh -c` to get string convenience back.
- Filenames and hostnames count as user input. So do values from your own database if any user ever wrote them.
- If an argument starts with `-`, an attacker can smuggle flags (`--output=/etc/cron.d/x`). Use `--` to terminate option parsing where the tool supports it, and validate expected formats.
- If you genuinely need shell features (pipelines, globbing), construct the pipeline in code with multiple `spawn` calls, or quote with `shlex.quote` as a last resort and say why in a comment.
- Escaping with string replacement (`.replace("'", "\\'")`) is not a fix. Do not write it.

**Red flags that you're about to violate this:**
- "shell=True is simpler and this input comes from a trusted form..."
- "It's just a filename, filenames are harmless..."
- "I'll strip semicolons from the input first..."
- "This script only runs in CI, nobody malicious touches CI..."
- "The exec string version is what the docs show..."
- "I need the pipe character, so I have to use the shell..."
