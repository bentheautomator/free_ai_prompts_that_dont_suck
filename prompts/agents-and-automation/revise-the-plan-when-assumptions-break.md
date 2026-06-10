---
title: Revise the Plan When Its Assumptions Break
slug: revise-the-plan-when-assumptions-break
category: agents-and-automation
tags: [universal, agents]
works_with: all
severity: high
one_liner: "Executing steps four through seven of a plan that step two invalidated"
---

# Revise the Plan When Its Assumptions Break

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from marching through the remaining steps of a plan after discovering facts that made those steps wrong.

**[Copy-paste ready version](../../install/revise-the-plan-when-assumptions-break.md)** — just the instruction block, no explanation.

## The Problem

Plans are written at the moment of maximum ignorance — before the agent has touched the code. Then execution begins, and reality reports in. Step two reveals that the "small helper module" is actually imported by forty files. Step three discovers the API the plan assumed doesn't exist in this version. And the agent... proceeds to step four. As planned. The plan has become fiction, but it's written-down fiction, and written-down beats freshly-observed in the agent's loyalty rankings.

This is plan inertia, and it gets worse the better the agent is at following plans. Each step is executed faithfully; the faithfulness is the bug. An agent in execution mode evaluates "did I do step four?" rather than "does step four still make sense?", because re-evaluating the plan feels like scope-questioning, while executing it feels like discipline. The discovery that should have triggered a replan gets logged as a curiosity — "interesting, the module is larger than expected" — and then steamrolled.

The output is distinctive wreckage: work that is internally consistent with a plan and externally inconsistent with the codebase. Steps four through seven were performed correctly and should never have been performed at all.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Revise the Plan When Its Assumptions Break

NEVER execute the next step of a plan after discovering something that contradicts the assumptions the plan was built on. A plan is a prediction made before you had the facts; when the facts arrive, they outrank it.

The core problem: in execution mode you check "did I do the step?" instead of "is the step still right?" — so discoveries that invalidate the plan get noted and then steamrolled.

- When you write a plan, note what it assumes: which files are involved, what the API looks like, roughly how big the change is. Steps inherit their validity from these assumptions.
- After each step, before starting the next, run the check: did anything I just learned contradict an assumption? Surprises that matter include: the change is 10x bigger than expected, the thing the plan modifies doesn't exist or works differently, a dependency points the opposite direction, or the bug is in a different layer than assumed.
- On a broken assumption, STOP executing. Explicitly mark which remaining steps are still valid, which are now wrong, and replan the wrong ones. Do not keep "making progress" while you think about it — progress along an invalid plan is damage.
- If the discovery changes the size or nature of the task materially (a one-file fix is actually a cross-cutting refactor), pause and tell the user before continuing. They approved the small version.
- "The plan says so" is never a sufficient reason for an action. Each step must also make sense given everything you currently know.
- Distinguish surprise from inconvenience: a step being harder than hoped doesn't invalidate it. The trigger is contradiction of an assumption, not friction.

**Red flags that you're about to violate this:**
- "That's odd, but let me continue with the plan..."
- "Interesting — anyway, step four is..."
- "I'll deal with that discrepancy after finishing the remaining steps..."
- "The plan has been working so far..."
- "Replanning now would waste the planning I already did..."

---

## Why It Works

1. **It demotes the plan explicitly.** Agents treat the written plan as the authority because it's the most structured artifact in context. Stating "facts outrank the prediction" rewires the precedence that causes the steamrolling.

2. **It installs a per-step checkpoint.** The contradiction is usually noticed — and then nothing fires. Requiring an explicit "did anything just break an assumption?" check between steps gives the noticing somewhere to go.

3. **It lists what counts as a broken assumption.** "10x bigger," "doesn't exist," "wrong layer" make the trigger concrete, while the surprise-vs-inconvenience line stops the rule from firing on ordinary friction.

4. **It blocks progress-as-displacement.** The most common dodge is to keep executing "while figuring it out." Naming progress along an invalid plan as damage, not progress, removes the comfort of motion.

## Origin

An agent planned a five-step extraction of a "self-contained" pricing function into a shared package. Step two revealed the function read from request-scoped globals — the central assumption was false, and the plan's own step one had surfaced it in a grep. The agent noted "this has more coupling than expected" and executed steps three through five anyway, publishing a package that crashed on import everywhere outside a request context. Reverting and redoing it properly took longer than the original task.
