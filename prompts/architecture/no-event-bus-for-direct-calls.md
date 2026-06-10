---
title: No Event Bus for Direct Calls
slug: no-event-bus-for-direct-calls
category: architecture
tags: [universal, architecture, indirection]
works_with: all
severity: medium
one_liner: "An event emitted to exactly one known listener instead of a function call"
---

# No Event Bus for Direct Calls

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from routing a call through events, signals, or a message bus when the caller knows exactly who needs to act and needs them to act now.

**[Copy-paste ready version](../../install/no-event-bus-for-direct-calls.md)** — just the instruction block, no explanation.

## The Problem

The order service needs inventory reserved when an order is placed. The AI, having absorbed a decade of "decouple with events" content, emits `OrderPlaced` and writes an inventory listener — for a call with one consumer, known at compile time, whose success the order flow depends on. The function call became an event, and everything got worse: "go to definition" now dead-ends at `emit()`, the type checker can't see the connection, and the failure mode changed from "exception propagates to the caller" to "listener failed somewhere, the order succeeded anyway, and inventory is now wrong."

Events earn their cost under specific conditions: multiple independent consumers, consumers unknown to the producer (plugins), or genuinely fire-and-forget semantics where the producer must not care about completion. One known listener whose result matters meets none of these. What the indirection buys in that case is exclusively negative: invisible control flow, lost error propagation, lost transactionality (the listener may run outside the caller's transaction), and ordering questions that didn't exist before.

The AI defaults to events because "decoupled" pattern-matches as architecturally virtuous, and the prompt word "when" ("reserve inventory *when* an order is placed") reads like an event. But "when X, do Y, and X depends on Y succeeding" is the definition of a function call.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It gates events on present-tense facts.** "Multiple consumers exist today" and "consumers unknowable at build time" are checkable now; "might need it later" is the unfalsifiable claim that justifies every speculative event.

2. **It keys on outcome-dependence.** Whether the caller needs the result is the cleanest single discriminator between a call and a notification — and it's exactly the property events destroy.

3. **It prices the asymmetry of mistakes.** Call-to-event conversion later is mechanical; event-to-call conversion means untangling listeners, ordering assumptions, and retry semantics that grew around the bus. Defaulting to the call is the cheap-to-reverse choice.

4. **It includes the zero-listener test.** "Is the producer correct with no listeners attached?" exposes disguised dependencies in one question, with no architecture discussion required.

## Origin

An e-commerce backend reserved inventory via an in-process `OrderPlaced` event with exactly one listener. Under deploy-time restarts, a window existed where the event fired and the process died before the listener ran; the order was placed, inventory never decremented. It happened roughly once per deploy for months — rare enough to be dismissed as gremlins, common enough to oversell three product launches. The fix replaced the event with a function call inside the order transaction. Diff size: minus forty lines, including the listener registry nobody else had ever registered with.
