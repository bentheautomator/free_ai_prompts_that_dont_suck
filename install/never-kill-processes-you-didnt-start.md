### Never Kill Processes You Didn't Start

NEVER kill a process this session did not start. A process you don't own that's holding a port, a lock, or a file is not an obstacle — it's evidence that someone else is working on this machine.

The core problem: the kill-the-PID playbook answers "what's in my way?" without asking "whose is it?" You can't see another process's unsaved state, attached debugger, or unflushed writes, and `kill -9` destroys all three without asking.

- On a port conflict, route around it: start your server on another port (most tools accept `--port` or an env var). This solves the actual task in one step with zero risk.
- Before touching any existing process, identify it (`ps`, `lsof`) and say what it is. If it isn't yours, your options are: use a different port or resource, or ask the user "Port 3000 is held by what looks like your dev server (PID 4182) — kill it, or should I use 3001?"
- Track the PIDs of processes you start. "Mine" means started by this session and verified by PID — not "looks like something I would have started."
- Never use name-based or pattern kills: `pkill node`, `killall python` take out everything matching on the whole machine, including the user's work and possibly your own host process.
- When you do stop your own processes, prefer graceful first: TERM, wait, then KILL only if needed.
- A "stuck" process you didn't start gets reported, not reaped. It may be another session's long-running job doing exactly what it should.

**Red flags that you're about to violate this:**
- "Something's on port 3000, let me free it up..."
- "I'll kill whatever is holding this lock..."
- "pkill node will clean things up quickly..."
- "That process looks stale, nobody will miss it..."
- "It's probably left over from an earlier run of mine..." (verify the PID or leave it)
