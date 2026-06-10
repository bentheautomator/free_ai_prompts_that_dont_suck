### Guard Empty Variables in Destructive Commands

NEVER write or run a destructive command whose target is built from a variable without guarding the empty case. `rm -rf "$BUILD_DIR/"` deletes from the filesystem root when the variable is unset — the quotes don't save you, and `set -u` isn't always there.

The core problem: variables are unset for boring reasons (typos, unloaded config, env differences between machines), the shell substitutes empty and proceeds, and an empty path component turns a scoped delete into `rm -rf /` or `rm -rf ~`.

- In scripts: start with `set -u` (or `set -euo pipefail`) so unset variables are fatal instead of empty. This is non-negotiable in any script containing `rm`, `mv` to overwrite, `chown`, or `find -delete`.
- Use the no-fallback expansion for destructive targets: `rm -rf "${BUILD_DIR:?BUILD_DIR is not set}/"` — the `:?` aborts with a message instead of expanding to nothing.
- Validate before destroying, explicitly: check the variable is non-empty AND the path exists AND it's the kind of path you expect (`[[ -n "$BUILD_DIR" && -d "$BUILD_DIR" && "$BUILD_DIR" == */build* ]]`). Refuse `/`, `$HOME`, and suspiciously short paths outright.
- Echo the resolved target before the destructive line acts on it: `echo "Deleting: '$TARGET'"` makes an empty expansion visible as `Deleting: ''` — in logs and in your own pre-run review.
- The same trap exists outside bash: Python `shutil.rmtree(os.environ.get("BUILD_DIR", ""))`, Makefiles (`rm -rf $(OUTDIR)/`), CI YAML interpolation. Guard them all: empty-check before any rmtree/recursive delete on a constructed path.
- When *running* an existing script that takes path variables, read it for this pattern first and confirm the variables are set in the current environment.

**Red flags that you're about to violate this:**
- "The variable is set right there at the top of the script..."
- "This script always runs through the Makefile, so the env is guaranteed..."
- "Quoting the variable makes it safe..."
- "Adding :? checks everywhere is noise..."
- "It worked on my run, the variable resolves fine..."
