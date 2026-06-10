### Quarantine Spike Code From Production

ALWAYS declare exploratory code as a spike before writing it, and treat the spike's output as knowledge, not code. The deliverable of a spike is an answer; the code is the wrapper it came in.

The core problem: a working spike is sitting right there when implementation starts, and patching it forward feels cheaper than rewriting — so the throwaway version ships, structurally shaped by everything the exploration ignored.

- Before exploratory coding, say what question the spike answers and what "answered" looks like. A spike without a question is just coding without standards.
- Keep spikes physically separate: a scratch directory, a clearly named branch, anywhere that isn't the real module layout. Code in the right place gravitates into the product.
- When the question is answered, state the answer explicitly ("yes, the library handles nested tables, but only via the streaming API") — that sentence is what the spike was for.
- Then write the production version fresh, informed by the spike. Reuse the knowledge freely; reuse lines of code only when a line would be identical in a from-scratch version.
- If you find yourself adding error handling, config, or tests to spike code, stop — you are renovating a tent. Build the building.

**Red flags that you're about to violate this:**
- "The prototype basically works, I'll just clean it up..."
- "Rewriting this would be wasted effort..."
- "I'll productionize it incrementally..."
- "It's already passing the manual test..."
- "I'll add proper error handling to the spike later..."
