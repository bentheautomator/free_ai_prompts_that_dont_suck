---
title: Print the State, Don't Guess It
slug: print-the-state-dont-guess-it
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: high
one_liner: "AI theorizing about runtime values it could simply print and look at"
---

# Print the State, Don't Guess It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from reasoning in circles about what a variable "probably" contains instead of printing it and looking.

**[Copy-paste ready version](../../install/print-the-state-dont-guess-it.md)** — just the instruction block, no explanation.

## The Problem

"At this point, `config.retries` is probably 3, so the loop should..." — and there it is, a debugging session built on a novel. AI assistants will produce paragraphs of careful reasoning about what values flow through a program, deduced from reading the code, when one inserted `print(f"retries={config.retries!r}")` and one run would replace the entire chain of "probably" with a fact. The model defaults to static reasoning because reading and inferring is its native mode, while instrumenting and executing requires acting on the world.

The problem with simulated execution is that the bug, by definition, lives exactly where the simulation diverges from reality. If the AI's mental model of the values were correct, the code would work. Every "should be," "presumably," and "at this point we know" in a debugging narrative is a place where the AI is asserting the very thing that's in question. When the bug is that `config.retries` is the *string* `"3"`, no amount of code-reading catches it — the code looks right, because the code *is* right; the data is wrong.

Sessions run this way have a distinctive failure smell: long, articulate, internally consistent explanations of behavior the program does not actually exhibit.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Print the State, Don't Guess It

NEVER build a debugging theory on what a runtime value "probably" is when you can print it and know. Two rounds of speculation about program state means it's time to instrument and run.

The bug lives precisely where your mental model diverges from reality, so a theory derived purely from reading code asserts exactly what's in question.

- When your reasoning includes "should be," "probably contains," or "at this point X is" — stop and verify: add a print/log at that point, run the reproduction, read the actual value
- Print values with type information visible (`repr()` in Python, `JSON.stringify` or `%o` in JS, `%#v` in Go) — "3" vs 3 and "empty string" vs null are where bugs hide
- Instrument the boundaries: function inputs and outputs, before/after the suspicious transformation, what was sent vs what came back
- Use a debugger or REPL where available; otherwise temporary prints are fine — verify state by whatever means executes the real code
- Check intermediate values, not just the final wrong answer: find the first point in the pipeline where reality diverges from expectation, because that's where the bug is
- One observed value outranks any amount of inferred narrative; when they conflict, the observation wins and the narrative is rebuilt

**Red flags that you're about to violate this:**
- "By this point, the list should contain the parsed records..."
- "The value is presumably coming from the constructor, so it must be..."
- "Tracing through the logic mentally: x is 5, then doubled..."
- "I don't need to run it; the data flow is clear from the code..."
- A third paragraph of reasoning about state with zero executions in between
- Being unable to say the actual observed value of the variable your theory depends on

---

## Why It Works

1. **It catches the divergence at its source.** The instruction's core reframe — your mental model failing *is* the bug — explains why simulation can't find what simulation got wrong, which dissolves the "I can see it from the code" rationalization.

2. **It sets a concrete trigger.** "Two rounds of speculation → instrument" converts a vague virtue (be empirical) into a tripwire the AI can actually detect itself hitting.

3. **It targets type-invisible bugs.** Mandating `repr`-style output names the specific class of bug (string "3", trailing whitespace, None vs empty) that pure code-reading is structurally blind to.

4. **It directs *where* to look.** "First point where reality diverges" turns printing from scattershot logging into a bisection of the data pipeline.

## Origin

An aggregation endpoint returned totals that were slightly wrong, and an assistant produced four successive theories from reading the code — float precision, timezone boundaries, a join duplicating rows, cache staleness — each with a fix attempt, each wrong. A developer added one log line printing the raw input rows: the upstream service was sending amounts as strings, and `"10" + "20"` had been concatenating to `"1020"` before a lossy parse. Every one of the four theories had assumed the inputs were numbers, and not one run had ever checked.
