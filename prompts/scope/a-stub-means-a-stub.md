---
title: A Stub Means a Stub
slug: a-stub-means-a-stub
category: scope
tags: [universal, scope]
works_with: all
severity: medium
one_liner: "AI fully implementing a function you asked it to stub out"
---

# A Stub Means a Stub

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from delivering a complete implementation when a placeholder was explicitly requested.

**[Copy-paste ready version](../../install/a-stub-means-a-stub.md)** — just the instruction block, no explanation.

## The Problem

"Stub out the payment client for now — I just need the interface so I can build the checkout flow against it." Twenty minutes later there's a full payment client: real HTTP calls, auth header construction, response parsing, an error hierarchy. The AI heard "stub" and delivered "finished," because finishing is what it knows how to want.

Stubs are deliberate engineering, not laziness the AI should compensate for. The user asked for a placeholder because the real implementation is blocked (no API keys yet), deferred (design not settled), out of scope (another team owns it), or intentionally fake (for tests or demos). Implementing it for real defeats each of those purposes at once: the unsettled design gets prematurely settled by whatever the AI guessed, the checkout work that needed a predictable fake now calls something that makes real network requests, and the "temporary" implementation becomes de facto production code without ever being designed — because removing working code feels wasteful, so it stays.

There's a quieter cost too: a stub is a planning artifact. It marks the boundary of today's work. An AI that fills in every stub it's asked to create is erasing the user's plan and substituting its own, which is the opposite of helping.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### A Stub Means a Stub

When asked for a stub, placeholder, skeleton, or mock, deliver exactly that: the shape without the substance. NEVER fill in the real implementation.

The core problem: a stub is a deliberate boundary marking work as blocked, deferred, or owned elsewhere, and implementing it for real erases that plan and settles unsettled decisions with your guesses.

- A stub has the requested signature and an inert body: return a fixed plausible value, raise NotImplementedError, or no-op, whichever fits the user's stated purpose
- Make the placeholder status unmissable: a `# STUB:` or `// TODO:` comment stating what the real version will do
- No real I/O from a stub, ever: no network calls, file writes, or database access inside something requested as fake
- Match the requested fidelity: "stub it" means minimal; "make it return realistic test data" means realistic data, still no real logic
- Do not "upgrade" adjacent stubs you encounter while working; existing placeholders are other people's planning artifacts
- If you know enough to write the real implementation and believe it would help, say so after delivering the stub ("I could implement this for real using X; want that?") and let the owner of the plan decide

**Red flags that you're about to violate this:**
- "I have enough context to just implement this properly..."
- "A real implementation is more useful than a placeholder..."
- "I'll make the stub actually work so they're not blocked later..."
- "Stubbing feels lazy when the full version is only 50 more lines..."
- "I'll implement it but they can treat it as a stub..."

---

## Why It Works

1. **It explains what a stub is for.** The AI models stubs as unfinished work; reframing them as boundary markers in someone's plan makes "finishing" them legible as overwriting the plan, not completing it.

2. **It defines stub mechanically.** "Requested signature, inert body, unmissable marker" is concrete enough to produce, removing the ambiguity the AI fills with implementation.

3. **It bans real I/O categorically.** The worst version of this failure is a "stub" with live side effects; an absolute no-I/O rule survives even when the AI fudges everything else.

4. **It routes capability into an offer.** The AI often genuinely could implement the real thing; the post-delivery offer lets that capability surface without letting it override the request.

## Origin

A developer building a notification flow asked for a stubbed email sender so they could test the flow's logic without sending anything. The assistant implemented a working sender instead, wired to SMTP settings it found in a dev config that, for legacy reasons, pointed at a production relay. A test run emailed 312 real customers a notification template containing placeholder text. The apology email was, at least, sent intentionally.
