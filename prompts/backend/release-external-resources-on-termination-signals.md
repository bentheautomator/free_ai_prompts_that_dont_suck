---
title: Release External Resources on Termination Signals
slug: release-external-resources-on-termination-signals
category: backend
tags: [universal, backend, reliability]
works_with: all
severity: high
one_liner: "Stops killed processes from leaving stale locks and leases behind"
---

# Release External Resources on Termination Signals

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents processes that ignore SIGTERM from abandoning distributed locks, leases, temp files, and registrations that haunt the system after they're gone.

**[Copy-paste ready version](../../install/release-external-resources-on-termination-signals.md)** — just the instruction block, no explanation.

## The Problem

Processes don't exit in production; they get told to exit. Deploys, autoscaling, node drains, and operators all deliver SIGTERM — and code that AI assistants write almost never listens for it. The default outcome is an abrupt death, and the problem isn't only the in-flight requests (drain those — that's its own rule). It's everything the process *holds in the outside world* at the moment it dies: a distributed lock in Redis, a leadership lease, a claimed-but-unfinished row marked `processing`, a service-discovery registration, gigabytes of temp files on a shared volume, a session in a third-party API with a seat limit.

None of that cleans itself up when the process vanishes. The next leader can't take over because the dead one still "holds" leadership. The scheduled job never runs again because its lock file says an instance from last Tuesday is busy. Rows sit in `processing` purgatory that no worker will touch. The licensed-connection quota fills with ghosts until real instances are refused. Each of these is a mystery outage later, with the culprit long gone from the process table.

Assistants skip signal handling because Ctrl-C in dev "works" — the OS reclaims memory and file descriptors, so it looks like cleanup is automatic. The OS reclaims what the *kernel* gave you. It has no idea about the lock you wrote into Redis.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Release External Resources on Termination Signals

Handle SIGTERM (and SIGINT) in every long-running process, and use the handler to release every external resource the process holds. The OS reclaims memory and file descriptors at death; it does NOT release distributed locks, leases, claimed jobs, registrations, or temp files — those persist as ghosts unless you release them.

- Register a shutdown handler at startup (`signal.signal`/`process.on('SIGTERM')`/`signal.NotifyContext`) that runs an ordered cleanup: stop taking new work, then release in reverse-acquisition order — un-claim in-progress job rows (reset to `pending`), release distributed locks and leases, deregister from service discovery, close broker consumers cleanly (so partitions rebalance now, not at session timeout), delete temp/spool files, end metered third-party sessions.
- Bound the cleanup with a deadline shorter than the platform's kill timeout (Kubernetes default: 30s to SIGKILL). A hung cleanup step must not block the rest — best-effort each item, log what released and what didn't.
- Belt and braces: every lock, lease, and claim must ALSO have a TTL or heartbeat so a SIGKILL, OOM, or kernel panic — which no handler survives — heals itself. The signal handler makes recovery instant; the TTL makes it inevitable.
- Make startup tolerant of your own ghosts: on boot, reap expired claims and stale registrations left by less graceful ancestors.
- Exit with a meaningful code after cleanup so the supervisor can distinguish graceful from crashed.
- Don't acquire what you can't release: if a resource has no TTL and no cleanup path, that's a design flaw to fix before shipping, not after the first node drain.

**Red flags that you're about to violate this:**
- "The OS cleans everything up when the process exits."
- "Deploys are rare, a stale lock once in a while is fine."
- "The TTL will expire eventually." (Eventually = your job is down until then, every deploy.)
- "Signal handling is platform boilerplate, not app logic."
- "Ctrl-C works fine locally."
- "We'll just manually delete the lock if it gets stuck." (You have just scheduled future 2 a.m. work.)

---

## Why It Works

1. **It corrects the kernel-cleanup illusion.** The assistant's mental model — "exit frees everything" — is true for process-local resources and false for everything written into external systems. Stating the boundary explicitly is what changes the generated code.
2. **It pairs the handler with TTLs, covering both death modes.** SIGTERM handlers cover graceful kills; TTL/heartbeats cover SIGKILL and panics. Either alone leaves a hole — together, recovery is instant when possible and bounded when not.
3. **It orders and bounds the cleanup.** Reverse-acquisition order prevents releasing a lock while still processing under it; the deadline prevents the cleanup itself from earning a SIGKILL mid-release.
4. **It adds startup reaping.** Self-healing on boot means one missed cleanup degrades the system for minutes, not until a human notices the ghost.

## Origin

A report-generation service used a Redis lock with no TTL to ensure a single active generator. A routine node drain SIGKILLed the pod after its nonexistent SIGTERM handler ignored the warning; the lock lived on, held by a pod that didn't. Every subsequent instance dutifully waited its turn behind the ghost — reports silently stopped for two and a half days until someone ran `redis-cli DEL` by hand. The fix: a 60-second TTL with heartbeat, a SIGTERM handler that releases it, and a startup sweep. Total diff: under forty lines.
