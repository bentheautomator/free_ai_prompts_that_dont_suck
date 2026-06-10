---
title: Never Kill Long-Running Jobs for Convenience
slug: never-kill-long-running-jobs
category: code-safety
tags: [universal, processes]
works_with: all
severity: critical
one_liner: "AI killing hours-deep jobs to free a port or tidy up the process list"
---

# Never Kill Long-Running Jobs for Convenience

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from terminating a process that's hours into unrecoverable work because it was in the way.

**[Copy-paste ready version](../../install/never-kill-long-running-jobs.md)** — just the instruction block, no explanation.

## The Problem

Port 8080 is taken, so the AI kills whatever holds it. Whatever held it was six hours into an eight-hour data processing run. Or the machine feels slow, so the AI kills the heaviest process — the model training job at epoch 47 of 60. Or a script "looks hung" after producing no output for two minutes, so the AI terminates and restarts it; it was inside a long compression step. A process is a line in `ps` to the AI. To the user it's the afternoon, or the GPU budget, or the batch window that doesn't reopen until tomorrow.

Killing a process is instant and the cost is invisible: progress is state inside the process or in half-written checkpoints, and `kill` doesn't print "you just discarded 6 hours." AI assistants kill freely because in their experience processes are cheap — dev servers, watchers, REPLs — things you restart without loss. They apply that model to processes where restart means starting over.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It makes elapsed time visible before the kill.** `etime` converts the invisible cost into a number the AI must read; almost nothing with six hours on the clock gets killed after that number is on screen.

2. **It establishes ownership as a boundary.** "A process you didn't start is someone else's" gives the AI a clean rule that doesn't depend on guessing what the process does.

3. **It reroutes the port-conflict reflex.** The most common kill trigger gets an explicit better path (bind elsewhere), so the destructive option stops being the path of least resistance.

## Origin

An assistant spinning up a dev server found port 8000 occupied and killed the occupant to proceed. The occupant was a dataset preprocessing job seven hours into a nine-hour run, serving its progress dashboard on that port. No checkpointing — the job's author had planned to add it "after this run." The dev server, for what it's worth, started fine.
