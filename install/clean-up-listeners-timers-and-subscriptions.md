### Clean Up Listeners, Timers, and Subscriptions

NEVER register a callback on something that outlives the registering scope without writing the matching teardown in the same change. Every `on`/`addEventListener`/`subscribe`/`setInterval`/`setTimeout`-that-reschedules must have a paired `off`/`removeEventListener`/`unsubscribe`/`clearInterval` wired to the owner's lifecycle.

A registration on a long-lived object (global emitter, window, document, store, socket, scheduler) pins the callback and everything its closure captures until explicitly removed. Re-running the registering code stacks duplicates.

- Write the cleanup at the same moment as the registration: return the unsubscribe function, use the framework's disposal hook (unmount/destroy/dispose effect cleanup), or use `AbortController`/`once` where supported.
- Be suspicious of any subscription created per request, per render, per reconnect, or per retry. Those paths run many times; each run must remove what the last run added or you accumulate one handler per execution.
- Keep a reference to the exact handler you registered. An inline anonymous function cannot be removed later.
- Timers that reschedule themselves need an owned cancel path; check a disposed flag before rescheduling.
- Verify by exercising the lifecycle: mount/unmount or connect/disconnect the thing 100 times and confirm handler counts and heap return to baseline (`getEventListeners`, `listenerCount()`, heap snapshot). One pass through the happy path proves nothing about accumulation.

**Red flags that you're about to violate this:**
- "The component rarely unmounts, so cleanup doesn't matter."
- "Garbage collection will take care of it."
- "I'll add the teardown in a follow-up."
- "It's just one listener."
- "The framework probably cleans this up automatically."
- "Removing it needs a reference and the inline arrow is cleaner."
