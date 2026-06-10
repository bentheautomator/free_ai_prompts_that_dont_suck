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
