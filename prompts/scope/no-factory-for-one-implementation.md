---
title: No Factory for One Implementation
slug: no-factory-for-one-implementation
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: medium
one_liner: "AI wrapping a single implementation in factories and interfaces it doesn't need"
---

# No Factory for One Implementation

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from building factories, interfaces, and abstract base classes around a class that has exactly one implementation.

**[Copy-paste ready version](../../install/no-factory-for-one-implementation.md)** — just the instruction block, no explanation.

## The Problem

You ask for a class that sends email through your provider. You get `EmailSender` — plus `AbstractNotificationSender`, `SenderInterface`, `SenderFactory.create("email")`, and a registration dict mapping one string to one class. Five constructs, one behavior. To find out what actually happens when an email sends, a reader now traverses three files and a lookup table.

AI assistants generate this because design-pattern literature is overrepresented in what they learned from, and patterns look like seniority. A factory signals "I thought about extensibility." But extensibility for variants that don't exist is pure cost: every layer of indirection is a place a stack trace gets longer, a "go to definition" lands on an interface instead of code, and a new contributor asks which of the five types they're supposed to use.

The kicker is that speculative abstractions are usually wrong. When the second implementation finally arrives, it needs a different shape than the interface guessed, and now someone has to refactor through the abstraction instead of just writing the abstraction correctly, once, with two real examples in hand.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Factory for One Implementation

NEVER create a factory, interface, abstract base class, or registry for a class that has exactly one implementation. Write the concrete class and use it directly.

The core problem: indirection built for hypothetical variants makes real code harder to find and read, and the guessed abstraction is usually the wrong shape when a second implementation actually appears.

- One implementation means: instantiate the class directly at the call site or via plain dependency injection, with no lookup layer
- Do not create `XInterface`, `AbstractX`, or `BaseX` alongside the only `X`
- Do not add a `create()`/`build()` factory function whose body is a single constructor call
- Do not add string-keyed registries, plugin maps, or `__init_subclass__` registration for one entry
- Abstractions are earned by the second concrete implementation existing in the same change, not by the possibility of one
- If you believe a second implementation is genuinely imminent, write the concrete class as asked and note in one sentence that an interface could be extracted later; extraction from working code is cheap

**Red flags that you're about to violate this:**
- "I'll define an interface first so this stays flexible..."
- "A factory makes it easy to add more senders later..."
- "Coding to abstractions is best practice, so..."
- "This keeps the implementation swappable for testing..."
- "I'll add a registry now so future types just plug in..."
- "It's the pattern a senior engineer would use here..."

---

## Why It Works

1. **It sets a concrete trigger for abstraction.** "When the second implementation exists in the same change" replaces the vague "when it might be needed," which the AI always answers with yes.

2. **It reframes patterns as cost, not signal.** The AI equates design patterns with quality; naming indirection's price (longer traces, dead-end navigation, choice paralysis) breaks that equation.

3. **It pre-empts the testing excuse.** "Swappable for testing" is the most respectable-sounding rationalization; the rule names it as a red flag so it can't pass as a requirement.

4. **It makes the cheap path explicit.** Stating that extraction-later is cheap removes the fear that skipping the abstraction now creates expensive work later, which is the engine behind speculative design.

## Origin

A backend team asked an assistant for a class to push events to their single message broker. It delivered an abstract publisher, a broker interface, a factory with a string-keyed registry, and a config option to select the implementation, of which there was one. Eight months later the team did add a second broker, and the inherited interface fit it so poorly that they deleted the entire abstraction and wrote a new one in an afternoon. The original five-file pattern had cost review time on every change that touched it and helped exactly never.
