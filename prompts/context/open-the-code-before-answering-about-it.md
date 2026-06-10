---
title: Open the Code Before Answering About It
slug: open-the-code-before-answering-about-it
category: context
tags: [universal, verification, grounding]
works_with: all
severity: high
one_liner: "AI answering 'how does auth work here' without opening a single auth file"
---

# Open the Code Before Answering About It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from answering questions about your codebase using a generic codebase it imagined.

**[Copy-paste ready version](../../install/open-the-code-before-answering-about-it.md)** — just the instruction block, no explanation.

## The Problem

"How does authentication work in this app?" is a question about one specific repository. The AI can answer it two ways: investigate the repo, or describe how authentication generally works in apps like this and present that as the answer. The second is faster, fluent, often 70% right — and the user has no way to tell which one they got. A confident paragraph about middleware, JWT validation, and session refresh reads identically whether it came from `src/auth/` or from the statistical average of every Express tutorial ever written.

That missing 30% is where the user's actual question usually lives. They asked because their app does something specific — a custom token rotation, a legacy cookie path, an SSO edge case. The generic answer paves over exactly the part that made the question worth asking. Worse, plausible-but-wrong architecture descriptions become the user's mental model. They make their next three decisions based on a description of a codebase that doesn't exist.

This isn't about effort; it's about honesty of method. A question about *this* code has one valid evidence source, and it's not the prior.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Open the Code Before Answering About It

NEVER answer a question about this project's code without opening the relevant files first. An answer assembled from how similar projects usually work is not an answer about this project — it's a guess delivered in the voice of one.

Generic answers are most dangerous precisely when they're plausible, because the user can't distinguish investigation from improvisation.

**When asked how something works in this codebase:**
- Locate the relevant code before composing any answer — search for the feature's entry points, then read them
- Trace the actual path: follow the real imports and calls, don't bridge gaps with "and then presumably it..."
- Anchor claims to evidence: cite file paths and function names you actually read, so the user can verify and so you can't drift into generality unnoticed
- If the code contradicts the standard pattern, the code wins — report the weird thing you found, not the clean version you expected
- If you can't find the relevant code, say that and ask for a pointer; "I couldn't locate where X happens" is a useful answer, a fabricated architecture is sabotage
- Scale the investigation to the question — a one-line question may need one file, but it never needs zero files

**Red flags that you're about to violate this:**
- "In a typical setup like this, the flow would be..."
- "This is almost certainly using the standard middleware pattern..."
- "I can describe this accurately without looking — it's a common stack..."
- "Reading the files would take a while; the general answer is close enough..."
- "It presumably refreshes the token here..."
- Composing an architecture explanation while your session contains zero reads from the relevant directory

---

## Why It Works

1. **It exposes the camouflage.** The core hazard is that improvised and investigated answers are indistinguishable to the reader. Naming that asymmetry makes the AI accountable for which one it's producing.

2. **It bans the "presumably" bridge.** Most fabricated explanations are real fragments connected by invented transitions. Prohibiting gap-bridging forces the trace to follow actual calls or stop honestly.

3. **It requires citable anchors.** File paths and function names in the answer serve double duty: the user can spot-check, and the AI physically cannot cite a file it never opened.

4. **It pre-authorizes "I couldn't find it."** Much fabrication is the AI avoiding an answer that feels like failure. Defining the honest miss as the *useful* outcome removes the pressure to invent.

## Origin

A new team member asked their assistant how rate limiting worked in the service they'd just joined. The AI delivered a crisp, confident description of token-bucket middleware on the API gateway — standard for that stack, absent from this repo. The actual rate limiting lived in a Redis Lua script two services away. The engineer designed a feature around the imaginary middleware, presented it at planning, and learned the truth from a staff engineer in front of the whole team. The AI had never opened a single file to answer.
