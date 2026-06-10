### No Event Bus for Direct Calls

NEVER use events, signals, pub/sub, or a message bus for an interaction with one known consumer whose outcome the caller depends on. That interaction is a function call; write it as one.

Events replace a visible, typed, error-propagating call with invisible control flow — that price is only worth paying when you actually need what events provide.

- Events are justified when at least one is true: multiple independent consumers exist TODAY; consumers can't be known at build time (plugin systems); or the work is truly fire-and-forget AND failure must not affect the caller. Otherwise: direct call
- "Might have more subscribers later" doesn't count — the second consumer justifies the event when it arrives, and converting a call to an event then is a small, mechanical change
- If the caller needs the result, needs errors to surface, or needs the work inside its transaction, an event is wrong regardless of consumer count
- Don't create the in-process event for "decoupling" while both modules sit in the same deployable importing the same types; that's coupling with extra steps and worse stack traces
- When you legitimately emit an event, the producer must remain correct if zero listeners are attached — if it wouldn't be, the dependency is real and should be a call
- This cuts both ways: where the codebase has a real event architecture with multiple consumers, add your consumer as a listener — don't bolt a direct call across it

**Red flags that you're about to violate this:**
- "Emitting an event keeps these modules decoupled..."
- "Someone else might want to listen to this someday..."
- "The task said 'when an order is placed,' so it sounds like an event..."
- "Events make it more extensible..."
- "I'll fire the event and the listener will handle failures itself..."
