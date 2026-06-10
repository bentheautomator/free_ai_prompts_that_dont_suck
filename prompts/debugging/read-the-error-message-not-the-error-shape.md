---
title: Read the Error Message, Not the Error Shape
slug: read-the-error-message-not-the-error-shape
category: debugging
tags: [universal, debugging, errors]
works_with: all
severity: high
one_liner: "AI pattern-matching the error type and ignoring what the message says"
---

# Read the Error Message, Not the Error Shape

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from recognizing the *kind* of error and skipping the specific words that say exactly what's wrong.

**[Copy-paste ready version](../../install/read-the-error-message-not-the-error-shape.md)** — just the instruction block, no explanation.

## The Problem

`ECONNREFUSED 127.0.0.1:5433`. The AI sees "ECONNREFUSED," recognizes the species — connection problems, usually means the database isn't running — and recommends starting Postgres. Postgres is running fine. On port 5432. The error message *said* 5433; the AI never read past the part it recognized. The message contained the entire diagnosis — wrong port, almost certainly a typo'd env var — and it was discarded in favor of the most statistically common cause of that error class.

This is classification beating comprehension. Error strings are dense with specifics: the exact path that wasn't found, the exact column that doesn't exist, the exact type that couldn't be converted and what it couldn't be converted *to*, the expected vs. actual in a failed assertion. A model that has seen a million `ModuleNotFoundError`s carries a strong prior about what they mean in general, and that prior steamrolls the particulars of *this* one. The familiar shape triggers the cached answer.

The cost is debugging the median bug instead of your bug — reinstalling packages when the message names a typo'd import, checking credentials when the message says the hostname didn't resolve, chasing the famous cause while the actual cause is printed on the screen.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read the Error Message, Not the Error Shape

NEVER diagnose an error from its type or general shape alone. Read every specific word of the actual message — names, paths, ports, values, expected-vs-actual — before forming any theory.

Recognizing the error's species tells you the most common cause in the world; the message's specifics tell you the actual cause in front of you. When they conflict, the specifics win.

- Quote the exact message to yourself and account for every concrete detail in it: what file, what key, what port, what value, what did it expect, what did it get
- Check the specifics against reality before theorizing: does that path exist? is that the port you configured? is that name spelled the way you spell it in code?
- Treat any detail you can't explain as the lead, not noise — an unexpected port number or a slightly-wrong module name usually *is* the bug
- Resist the cached fix for the error class ("ECONNREFUSED means start the service," "ModuleNotFoundError means pip install") until the message's specifics confirm that story
- If the message includes expected/actual values, diff them character by character; the difference is frequently the whole answer
- Your stated diagnosis must reference the message's specifics, not just its type

**Red flags that you're about to violate this:**
- "This is a classic connection-refused error; the service must be down..."
- "ModuleNotFoundError — needs a pip install..." (the module name has a typo in it)
- "I know what this kind of error means..."
- "The details don't matter; the category tells the story..."
- Proposing a fix without being able to repeat what the message actually said
- Skimming past a number, path, or name in the error without checking it

---

## Why It Works

1. **It pits the prior against the evidence by name.** The failure is a strong class-level prior overriding instance-level data. Stating "specifics beat species" gives the AI an explicit tiebreaker for exactly that collision.

2. **It makes every detail an obligation.** Requiring each concrete element to be accounted for turns "5433" from skippable noise into a checklist item that has to be reconciled with the config.

3. **It flags the unexplainable detail as the lead.** Wrong-looking specifics (the port you never chose, the path with one wrong segment) are where these bugs live; the instruction promotes them from anomaly to primary suspect.

4. **It blocks the cached-fix reflex.** Naming the canned responses ("must be down," "pip install it") preempts the autopilot answer the error class triggers.

## Origin

A build failed with `Error: Cannot find module './utils/formatters'` and the assistant spent forty minutes on the famous causes: cleared node_modules, reinstalled, checked the package manager version, adjusted module resolution settings. The directory was named `formaters` — one 't' — and the message had been spelling out the exact wrong path from the first second. A human read the error aloud, slowly, and fixed it in one rename.
