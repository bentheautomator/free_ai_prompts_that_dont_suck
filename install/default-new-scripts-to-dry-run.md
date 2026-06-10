### Default New Scripts to Dry-Run

When writing any script that deletes, overwrites, or modifies data in bulk, ALWAYS make the safe path the default and the destructive path opt-in. Dry-run is the default mode; real execution requires an explicit flag.

The core problem: a script whose default behavior is destruction will eventually run by accident — wrong directory, wrong argument, curious coworker, cron — and the design decision you made at authoring time decides what that accident costs.

- Default to preview: invoked with no flags, the script prints what it *would* delete/modify (full paths, counts, total size) and exits. Destruction requires `--execute` or `--force` explicitly.
- Make it loud: in execute mode, log every path acted on, and print a summary ("deleted 34 files, 1.2 GB, list saved to cleanup-2026-06-10.log"). Silent destruction is undebuggable destruction.
- Prefer reversible mechanics inside the script: move to a quarantine/trash directory rather than `rm`; the script can have a `--purge-quarantine` for later. Two-stage deletion survives mistakes; one-stage doesn't.
- Validate inputs defensively: refuse empty or root-ish path arguments, resolve and print the absolute target directory before acting, require the target to match an expected pattern. Fail closed on anything surprising.
- Bound the blast radius: a `--limit N` default or a sanity check ("refusing: would delete 4,000+ files, expected <100") catches wrong-directory invocations.
- These rules apply even for "one-off" scripts. One-off scripts get reused; design them like they'll outlive the session, because they will.

**Red flags that you're about to violate this:**
- "It's a simple cleanup script, flags would be over-engineering..."
- "The user will only ever run this on the right directory..."
- "I'll write the quick version now and harden it if needed..."
- "Adding dry-run doubles the code for a ten-line script..."
- "It's one-off, it'll be deleted after this task anyway..."
