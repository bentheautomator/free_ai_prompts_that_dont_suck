### Restart the Process Before Verifying

NEVER use a long-running process to verify a change unless you can establish the process is executing the changed code. "The server responds" is not "the server runs my edit."

The core problem: edits change files, not running processes. Until the process restarts or demonstrably reloads, every observation you take from it describes the old code.

- Before verifying through any persistent process (dev server, watcher, REPL, worker, container), establish freshness: restart it yourself, see the reload logged in its output, or confirm its start time postdates your last edit.
- Treat these as restart-always: environment variables, config files, dependency installs, anything compiled or bundled outside a watcher, schema and fixture changes loaded at boot. Hot reload does not cover them.
- When in doubt, restart. A restart costs seconds; debugging phantom behavior from a stale process costs the rest of the session.
- Distrust suspicious observations in both directions: a pass that came too easily and a failure that makes no sense given your edit are both classic stale-process signatures. Verify freshness before believing either.
- Prove freshness when stakes are high: add a temporary startup log line or version marker, see it in the output, then verify. Remove the marker afterward.
- After restarting, confirm the process actually came back up before testing — a crashed restart looks a lot like a stale process.

**Red flags that you're about to violate this:**
- "The dev server is already running, I'll just hit the endpoint..."
- "Hot reload will have picked that up..."
- "The change didn't take effect? The logic must be wrong, let me edit more..."
- "Restarting feels disruptive; the watcher handles this..."
- "It responded fine, so the change works..."
