---
title: No Interfaces With One Implementation
slug: no-interfaces-with-one-implementation
category: architecture
tags: [universal, architecture, abstraction]
works_with: all
severity: high
one_liner: "AI inventing an interface, factory, and impl class for a single concrete thing"
---

# No Interfaces With One Implementation

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from wrapping a single concrete class in an interface, an abstract base, and a factory "for flexibility" nobody asked for.

**[Copy-paste ready version](../../install/no-interfaces-with-one-implementation.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant for a class that sends emails and you frequently get `EmailSender` (interface), `SmtpEmailSender` (the only implementation), `EmailSenderFactory` (returns the only implementation), and a config flag to choose between the one option. Three files where one was needed. The AI has seen this shape in a thousand enterprise tutorials, so it reproduces the ceremony as if it were the feature.

The cost is not the extra files today; it's the navigation tax forever. Every reader who clicks "go to definition" lands on an interface and has to hunt for the real code. Every signature change is now a two-file change. And the abstraction is almost always wrong, because it was designed against zero real second implementations — when the actual second backend arrives, the interface gets reshaped anyway.

AI assistants do this by default because speculative abstraction looks like diligence and costs nothing in the diff review. "Made it extensible" sounds like a gift. It's a loan, at interest, against every future edit.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Interfaces With One Implementation

NEVER create an interface, abstract base class, or trait that has exactly one implementation and no concrete second implementation planned in the current task. Write the concrete class; extract the interface when the second implementation actually arrives.

An abstraction designed against one example is guesswork, and it taxes every reader and every signature change until someone deletes it.

- One email sender means one class: `SmtpEmailSender` or just `EmailSender`, concrete. No `IEmailSender`, no `AbstractEmailSender`, no factory returning the only option
- "We might swap the database later" is not a second implementation; a second implementation is code that exists or is in this task's requirements
- Test doubles do not justify an interface in languages with duck typing, monkeypatching, or mocking libraries that fake concrete classes; only extract one if the language genuinely requires it for substitution, and say so
- If the codebase has an established convention of interfaces at a particular boundary (e.g., all repositories), follow the convention; this rule is about inventing new speculative ones
- When a real second implementation shows up, extract the interface FROM the two concrete examples; that interface will be shaped by evidence instead of imagination

**Red flags that you're about to violate this:**
- "I'll add an interface so it's easy to swap implementations later..."
- "This makes it more testable..." (the mocking library fakes concrete classes fine)
- "It's a best practice to program against interfaces..."
- "The factory keeps construction flexible..."
- "It only costs one extra file..."
- "Enterprise codebases always do it this way..."

---

## Why It Works

1. **It moves the justification to the second caller.** Abstractions earn their keep by unifying two real cases; the rule makes "a second implementation exists" the gate, which is checkable, instead of "might need it," which never is.

2. **It names the test-double excuse.** "For testability" is the rationalization that survives longest; pointing at mocking libraries removes it in the languages where it's false.

3. **It preserves real conventions.** By carving out existing codebase-wide patterns, the rule can't be misread as "delete all interfaces," so it doesn't fight the project's actual architecture.

4. **It promises a better interface later.** "Extract from two examples" reframes restraint as deferral, not loss — the AI isn't giving up the abstraction, it's waiting for the data to design it correctly.

## Origin

A payments service grew an `IPaymentProvider` interface, a factory, and a registry on day one, all serving the single card processor the company ever used. Eighteen months later a genuine second provider arrived, and its API was async-webhook based; the interface, designed around the first provider's synchronous calls, fit so badly that the team rewrote the abstraction anyway — after first having to understand and unwind the unused registry machinery. The speculative flexibility delivered zero reuse and one extra rewrite.
