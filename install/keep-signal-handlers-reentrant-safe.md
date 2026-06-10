### Keep Signal Handlers Reentrant-Safe

A signal handler does ONE thing: record that the signal happened, then return. All real work — logging, cleanup, closing resources, exiting — happens in normal code that notices the record.

Handlers interrupt arbitrary code mid-operation; anything non-reentrant they touch (allocators, loggers, locks, most of your program) may be in a torn state.

- The pattern: handler sets a `sig_atomic_t`/atomic flag or writes one byte to a self-pipe / wakes an event (`asyncio`'s `add_signal_handler`, Go's `signal.Notify` channel are this pattern built-in). The main loop checks the flag and performs shutdown in a sane context.
- Inside the handler, never: allocate, log, print, take locks, call into your database/network clients, or call anything not explicitly async-signal-safe. In C that's a short documented list; in higher-level languages, behave as if the list were just as short.
- Never touch shared mutable program state from a handler beyond the single flag. The code you interrupted will resume and assumes its invariants held while it was gone.
- Don't raise exceptions from handlers into arbitrary interrupted code as your shutdown mechanism (Python's default KeyboardInterrupt mid-`finally` is the canonical mess); convert the signal to an event your loop consumes deliberately.
- Make second signals meaningful: first SIGINT requests graceful shutdown via the flag; a second one, or a timeout, force-exits. A graceful path that hangs must not be the only path.
- Register handlers early and once; re-registering or registering from threads invites platform-specific surprises.

**Red flags that you're about to violate this:**
- "It's just one log line to say we're shutting down."
- "Python/Node handles signals safely, so the handler can do anything."
- "The handler needs the lock to clean up the shared state properly."
- "Cleanup must happen *in* the handler or the process might die first."
- "It's worked every time I've Ctrl+C'd it."
