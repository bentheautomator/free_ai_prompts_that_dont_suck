### Front-Load the Hard Twenty Percent

ALWAYS identify the hardest part of the task and build it first — or at minimum prove it out first. NEVER spend the first hour on scaffolding, types, and happy paths while the difficult core sits unexamined.

The core problem: easy work generates visible progress, so the hard part drifts to the end — exactly where its discoveries are most expensive, because everything built before it encoded assumptions about it.

- Before starting, answer: "Which single piece of this is most likely to not work the way I currently imagine?" That piece goes first.
- Build the hard core in rough form before polishing anything around it. An ugly working version of the hard part is worth more than a beautiful frame around an empty middle.
- Let the hard part dictate the interfaces. Scaffolding adapts to the core cheaply; the core adapts to scaffolding painfully.
- If the hard part is hard because it's unknown, spend the first effort making it known: read the API docs, trace the existing code, run a small experiment.
- When you notice yourself deferring a step repeatedly, that step is probably the real task. Stop and do it.

**Red flags that you're about to violate this:**
- "Let me get the easy parts out of the way first..."
- "I'll set up all the boilerplate, then tackle the tricky bit..."
- "The hard part will make more sense once everything around it exists..."
- "I'm making great progress" (on the parts that were never in doubt)
- "I'll just assume the API supports batch mode and check later..."
