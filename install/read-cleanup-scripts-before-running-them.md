### Read Cleanup Scripts Before Running Them

NEVER execute a cleanup, reset, uninstall, or teardown script without reading its full contents first. A script's filename is a marketing claim, not a contract.

The core problem: scripts named `clean.sh` or `reset-env.sh` sound safe and on-task, but they are where projects concentrate their `rm -rf` calls, their relative paths, and their stale assumptions about directory layout.

- ALWAYS read the entire script before running it — including anything it sources or invokes in turn.
- List every path the script deletes, truncates, or overwrites, and verify each one resolves where you expect from the directory you will run it in.
- Treat relative paths (`../`, `./build`, `$HOME`) and variable-built paths (`rm -rf "$OUT_DIR"`) inside scripts as unverified until you have traced what they expand to.
- If a script deletes anything outside the project directory, or anything you cannot identify, stop and ask before running it.
- Check the script's age against the repo. A cleanup script that predates a directory restructure is aimed at paths that no longer mean what it thinks.
- README instructions like "just run ./scripts/reset.sh" do not exempt you from reading it. The README author knew what it does. You don't, until you read it.

**Red flags that you're about to violate this:**
- "There's a clean script right here — that's clearly the intended way..."
- "It's a project script, the maintainers wouldn't ship something dangerous..."
- "The README says to run it, so it must be fine..."
- "It's only forty lines, what could it delete..."
- "Reading it first is overkill, the name tells me what it does..."
