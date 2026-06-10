### Wire New Code Into the Codebase

New code isn't done when it's written — it's done when something reaches it. ALWAYS complete the wiring: the registration, mounting, export, scheduling, or call that makes your new code part of the running system.

A handler the router doesn't know about is a 404 with excellent internals. The artifact is half the task; the connection is the other half, and it usually lives in a file you haven't opened yet.

**For every new piece of code, identify and complete its connection point:**
- Route handlers → registered in the router/URL config
- Middleware → inserted into the middleware chain, in the right position
- Components → imported and rendered by an actual parent (and exported from the barrel file if the project uses them)
- Event handlers/listeners → subscribed to the emitter, queue, or signal
- Migrations → named/numbered so the migration runner picks them up
- Scheduled jobs → an actual schedule entry in the cron/scheduler config
- CLI commands → registered with the command group/parser
- DI services → bound in the container/module providers
- Find the connection convention by looking at how an *existing* sibling is wired, and wire yours the same way
- After wiring, trace the path once: from entry point (URL, event, schedule, import chain) to your code, confirming each hop exists. If you cannot complete the wiring (e.g., the parent component is ambiguous), say so explicitly — never present unwired code as a finished feature

**Red flags that you're about to violate this:**
- "The handler is implemented — the feature is complete..."
- "They'll hook it up wherever it fits best..."
- "The registration is trivial, I'll focus on the logic..."
- "I've created the component; integration is a separate concern..."
- "The framework probably auto-discovers this..." (verified, or assumed?)
- Finishing a feature without having edited any file that *references* your new code
