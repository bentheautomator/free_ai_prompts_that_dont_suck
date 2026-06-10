### Never Kill Long-Running Jobs for Convenience

NEVER kill a process you didn't start without finding out what it is and what dies with it. A process can be hours into work that restarting does not resume.

The core problem: killing is instant and the cost is invisible — progress lives inside the process. The mental model of "processes are cheap, just restart" is true for dev servers and false for training runs, batch jobs, migrations of files, uploads, and encodes.

- Before killing anything, identify it: `ps -o pid,etime,command -p <pid>`, `lsof -i :<port>` for port holders. Pay attention to elapsed time — `etime` of 05:43:12 means five hours and forty-three minutes of something.
- A process you didn't start is someone else's process. State what it is and what killing it loses; let the user decide.
- For a port conflict, prefer every alternative to killing: use a different port, configure your service to bind elsewhere, ask whether the holder can be stopped cleanly.
- "Looks hung" requires evidence: check CPU usage, open files, output file growth (`ls -la` the output twice). Quiet is not stuck — long steps are silent.
- If termination is genuinely needed, attempt a graceful path first: does the job have checkpointing, a save-and-exit signal, a pause mechanism? `SIGTERM` before `SIGKILL`, always, and time for handlers to flush.
- Never `pkill`/`killall` by name pattern — name matching kills strangers.

**Red flags that you're about to violate this:**
- "Something's on that port, I'll free it up..."
- "This process is eating all the CPU, killing it will help..."
- "No output for a while — it's hung, restart it..."
- "I'll pkill python to clear out the stragglers..."
- "Whatever it is, they can just run it again..."
