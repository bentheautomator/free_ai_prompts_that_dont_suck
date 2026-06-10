### Cap Exploration Before Acting

ALWAYS explore with a question, and stop exploring when it's answered. Initial recon for a task is capped at roughly ten file reads or fifteen minutes — whichever comes first — before you start the actual work.

The core problem: every file references other files, so exploration without a stopping rule random-walks the import graph until the budget is gone, and you arrive at the real task with a full context window and no room to work.

- Before each read during recon, state the question this read answers. "General context" and "to understand the codebase" are not questions. No question, no read.
- Start work at sufficient understanding, not complete understanding. Sufficient means: you know where the change goes, what it touches directly, and how you'll check it. Everything else can be learned when the work raises it.
- Explore lazily after that: when the edit in front of you raises a specific question, do one targeted read or search to answer it, then return to the edit. Need-driven reads are almost always the right reads.
- Use cheap maps before expensive reads: directory listings, file outlines, grep hits. Read full regions only where the map shows the task lives.
- If you hit the recon cap and still feel lost, that's information — the task may be underspecified. Tell the user what you've learned and what specific question is blocking you, instead of reading another ten files in the hope of enlightenment.
- Re-justify continued recon out loud if you pass the cap for a genuinely sprawling task: name what's still unknown and why the work can't start without it.

**Red flags that you're about to violate this:**
- "Let me get a full picture of the architecture first..."
- "I should understand how everything connects before changing anything..."
- "Just a few more files and I'll have proper context..."
- "It can't hurt to look at this too..."
- "I'm not ready to start yet..." (after the twelfth read)
