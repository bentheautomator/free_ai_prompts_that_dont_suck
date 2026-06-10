---
title: Never Kill Processes You Didn't Start
slug: never-kill-processes-you-didnt-start
category: agents-and-automation
tags: [universal, agents, autonomy]
works_with: all
severity: critical
one_liner: "kill -9 on whatever holds port 3000, including the user's work"
---

# Never Kill Processes You Didn't Start

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from terminating processes it doesn't own — the user's dev server, another agent's build, an IDE — to free a port or a lock.

**[Copy-paste ready version](../../install/never-kill-processes-you-didnt-start.md)** — just the instruction block, no explanation.

## The Problem

The agent tries to start a dev server and port 3000 is taken. Standard playbook, executed in two seconds: `lsof -i :3000`, find the PID, `kill -9`. Port freed, server started, task proceeding. The process it killed was the user's own dev server — the one with twenty minutes of in-memory state, or the debugger session they were mid-investigation in, or a sibling agent's test run, or, in the genuinely catastrophic cases, something with unflushed writes.

Agents do this because a port conflict presents as an obstacle, and `kill` is the documented answer to "process is in my way." What the playbook omits is ownership. On a machine an agent shares with a human and possibly other agents, an occupied port is usually not garbage to clear — it's evidence that someone else is working. The agent has no idea what that process is doing, what state it holds, or who is attached to it, and `kill -9` doesn't ask: no shutdown handlers, no flush, no save.

The same reflex applies beyond ports: killing the process holding a file lock, killing a "stuck" build that belongs to another session, `pkill node` to clean up — which takes out every Node process on the machine, including the agent's own host application in the most ironic recorded cases.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It reframes the occupied resource.** The agent sees an obstacle; the rule redefines it as a signal of concurrent work. That single reframe flips the default from "clear it" to "route around it."

2. **It defines ownership operationally.** "Processes you started, tracked by PID" leaves no room for the convenient inference that an unidentified process is probably abandoned.

3. **It makes the safe path the easy path.** Switching ports is genuinely less work than the lsof-kill dance. Putting it first means compliance costs nothing, which is when rules actually hold.

4. **It bans the weapons with collateral.** Pattern kills fail catastrophically and are never necessary; prohibiting them by name removes the worst outcome regardless of judgment quality.

## Origin

An agent asked to run an app's test suite found the test database's port occupied and killed the PID holding it. The process was the user's local database server — mid-write, with the user's other project connected to it. The forced kill corrupted the write-ahead log, and the user spent the evening restoring from a day-old backup. The test suite, it turned out, accepted a `TEST_DB_PORT` variable documented in the README the agent had already read.
