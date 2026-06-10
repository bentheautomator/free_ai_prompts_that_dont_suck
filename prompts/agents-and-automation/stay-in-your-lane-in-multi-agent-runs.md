---
title: Stay in Your Lane in Multi-Agent Runs
slug: stay-in-your-lane-in-multi-agent-runs
category: agents-and-automation
tags: [universal, agents, multi-agent]
works_with: all
severity: medium
one_liner: "Agents completing a sibling's assigned module twice, differently"
---

# Stay in Your Lane in Multi-Agent Runs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents an agent in a multi-agent run from doing work assigned to a sibling, producing duplicate, conflicting implementations.

**[Copy-paste ready version](../../install/stay-in-your-lane-in-multi-agent-runs.md)** — just the instruction block, no explanation.

## The Problem

A multi-agent run divides the work: agent one takes the parser, agent two takes the validator, agent three takes the CLI. Agent one finishes early, notices the validator "isn't done yet," and — being helpful — implements it. Now the validator exists twice: agent one's version, wired into the parser the way agent one likes, and agent two's version, arriving twenty minutes later, wired differently. The integration step inherits two incompatible implementations of one component, plus a parser that secretly depends on the wrong one.

Agents cross lanes because the assignment boundary is invisible from inside the work. Agent one sees a missing function its code needs, and missing-things-get-built is the deepest reflex an agent has. It doesn't model that the gap is someone else's task in progress — that the absence is scheduled. Helpfulness, eagerness to ship a "complete" result, and zero awareness of sibling progress all push the same direction: fill the gap now.

The cost isn't just duplication. The lane-crossing agent makes design decisions that belong to the sibling's task — interface shapes, naming, error contracts — and the sibling builds on different ones. The merge doesn't just have conflicts; it has two architectures.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stay in Your Lane in Multi-Agent Runs

NEVER implement something assigned to another agent in your run, even if it's missing and your work needs it. In a divided task, a gap where a sibling's component should be is scheduled absence, not abandonment — filling it creates two implementations and two architectures.

The core problem: assignment boundaries are invisible from inside the work. Your code needs a thing, the thing doesn't exist, and building missing things is your deepest reflex — but this missing thing is someone's task in progress.

- Know your assignment's edges. At task start, restate what you own and — equally important — what you don't. If the partition wasn't made explicit, ask the orchestrator or user for it before working near a boundary.
- When your work needs something from a sibling's lane that doesn't exist yet: code against the agreed interface (or propose one through the orchestrator), stub it locally for your tests if needed, and clearly mark the stub as placeholder for the sibling's component. Never ship your stub as the implementation.
- Finished early? Report done and ask for more work. Do not browse the shared plan for unstarted items to grab, and do not "polish" files in other lanes — improvements to a sibling's in-progress code are conflicts wearing a helpful hat.
- If you believe a sibling's lane is genuinely stalled or wrong, say so to the orchestrator or user — routing around them quietly means the run produces both your version and theirs.
- Interface changes are cross-lane by definition: if your task requires changing a shared contract, that goes through coordination, not unilateral edit — the siblings are building against the current one.
- Keep your outputs in your lane too: write only to the files and directories your assignment covers.

**Red flags that you're about to violate this:**
- "The validator isn't implemented yet, I'll just build it..."
- "I'm blocked on their part, so I'll do it myself..."
- "I finished early — let me pick up that other item from the plan..."
- "Their module would be better if I just adjusted it slightly..."
- "It's faster to change the shared interface than to ask..."

---

## Why It Works

1. **It reframes the gap.** "Missing" triggers building; "scheduled absence" triggers waiting or stubbing. The reframe attacks the exact perception that launches the lane-cross.

2. **It legitimizes stubs as the boundary tool.** The agent's real need — something to compile and test against — is met by an explicitly-marked placeholder, so respecting the boundary never blocks the agent's own progress.

3. **It routes early finishers and stall suspicions through the coordinator.** Both honest motives for grabbing sibling work get a sanctioned channel, which removes "I had no other option" from the rationalization set.

4. **It extends the lane to contracts and files.** Naming shared interfaces and out-of-lane writes as boundary violations closes the subtle crossings that don't feel like taking someone's task but wreck the merge just the same.

## Origin

In a three-agent run building an ETL pipeline, the agent assigned to extraction finished first and noticed the transform module was "still empty." It implemented a transform "so the pipeline would be testable end to end," choosing its own column-naming convention. The transform agent delivered its version an hour later, built to the originally agreed convention. Integration produced a pipeline where half the downstream queries used each naming scheme; reconciling them took longer than either implementation had.
