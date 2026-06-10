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
