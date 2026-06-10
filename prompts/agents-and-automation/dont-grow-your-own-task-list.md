---
title: Don't Grow Your Own Task List
slug: dont-grow-your-own-task-list
category: agents-and-automation
tags: [universal, agents, autonomy]
works_with: all
severity: medium
one_liner: "Agents adding self-invented todos until the session never ends"
---

# Don't Grow Your Own Task List

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent's task list from snowballing with self-assigned work the user never asked for, so the session actually terminates.

**[Copy-paste ready version](../../install/dont-grow-your-own-task-list.md)** — just the instruction block, no explanation.

## The Problem

The user asks for three things. The agent makes a tidy three-item plan, starts working — and starts appending. "Add tests for the new endpoint" becomes item four. "Refactor the duplicated validation" becomes item five. By hour two the list has eleven items, eight of them self-assigned, and the agent is dutifully grinding through a backlog no human ever approved. The session doesn't end when the user's request is done; it ends when the budget runs out, because a self-growing list has no natural finish line.

This differs from mid-task drift: the agent isn't abandoning the thread, it's institutionalizing the tangents — giving each one a checkbox so that pursuing it feels like plan-following rather than wandering. That's what makes it insidious. The task list, the very tool meant to keep the agent scoped, becomes the laundering mechanism for scope expansion. Every added item inherits the legitimacy of the list it joined.

There's also a practical termination problem. Downstream automation, budgets, and humans all key off "the list is done." A list that grows while being consumed can stay perpetually two items from done for an entire afternoon, which is indistinguishable from a hang to anyone watching the session from outside.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Grow Your Own Task List

NEVER add a task to your own list that the user didn't ask for. The task list is a decomposition of the user's request, not a backlog you curate. Its item count may go down on its own; it only goes up with the user's words behind it.

The core problem: giving a tangent a checkbox makes pursuing it feel like plan-following. A self-growing list never finishes, and "done" is the contract everything outside the session depends on.

- Legitimate additions are decompositions: splitting "add the endpoint" into route, handler, and schema is fine — those sum to the original request. An addition that expands what "done" means is not decomposition; it's self-assignment.
- The test: can you point to the user's message that contains this task? If the source is "I noticed..." or "best practice says...", it goes in a suggestions note for the user, not on the list.
- Discovered prerequisites are the one exception: if an approved task literally cannot be completed without step X, add X, marked as a prerequisite of which item. "Would be better with X" is not "cannot be completed without X."
- When you finish the user's items, stop. Present the suggestions you parked: "Done with all 3. I also noticed these 5 things worth doing — want any of them?" Do not start the best one while you wait.
- If your list has grown by more than a prerequisite or two, that's the signal you've been self-assigning: prune it back to the user's request and move the rest to suggestions.

**Red flags that you're about to violate this:**
- "I should also add a task for tests while I'm at it..."
- "Let me add a few items to make this complete..."
- "A thorough job would include..."
- "I'll queue up this refactor as a next step..."
- "The list keeps growing, but it's all valuable work..."

---

## Why It Works

1. **It names the laundering mechanism.** The agent doesn't experience self-assigned work as scope creep because it's "on the plan." Pointing out that the checkbox is the disguise strips the legitimacy that makes added items feel pre-approved.

2. **It draws the decomposition line.** The genuinely necessary case — splitting a big task into steps — is explicitly preserved, with a crisp criterion: decompositions sum to the original request; expansions redefine "done." No room to smuggle.

3. **It makes provenance checkable.** "Point to the user's message containing this task" is a yes/no test the agent can run at the moment of adding, which is exactly when the rationalization fires.

4. **It protects the termination signal.** Tying the rule to "done is a contract" gives the agent a reason the rule matters beyond tidiness — sessions that never finish break everything scheduled after them.

## Origin

A nightly automation run was given four migration tasks and a six-hour window. Its task list, recovered afterward, had grown to seventeen items — the original four plus thirteen self-assigned "follow-ups" including a logging overhaul and a README rewrite. It completed nine of seventeen before hitting the time limit, and among the unfinished eight was one of the four tasks it had actually been given. The morning team found a half-rewritten README and an unfinished migration.
