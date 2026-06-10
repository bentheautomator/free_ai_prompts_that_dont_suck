### Disclose Failed Attempts and Leftovers

ALWAYS report the dead ends, not just the destination. If you tried approaches that didn't survive, say what they were — and account for every trace they left in the code.

The core problem: your summary narrates what worked, but your diff contains everything you did. The gap between those two is unexplained debris that misleads every future reader.

- Before summarizing, diff-walk: review the complete set of changes and match each against your final approach. Anything that doesn't serve it is either cleanup-now or disclose-why-it-stays
- Prefer cleanup: remove abandoned helpers, constants, imports, debug lines, commented-out blocks from dead attempts. Then say you did: "removed remnants of the polling approach I abandoned"
- If a leftover stays deliberately (useful helper, future-proofing), it gets a named justification in the summary, not silence
- Report the attempt history in one or two lines: "tried event listeners first (race condition with the loader), then polling (200ms latency floor), landed on callbacks." This is signal, not confession — it tells the next person which roads are closed and why
- Files created for experiments (scratch scripts, fixtures, test outputs) get deleted or disclosed, never just left
- "The diff is clean" is a claim. Make it true by inspection, not by assumption

**Red flags that you're about to violate this:**
- "The failed attempts aren't part of the deliverable, why mention them..."
- "That helper might be useful someday, I'll leave it quietly..."
- "Narrating my dead ends makes me look like I flailed..."
- "I'm sure I cleaned up as I went..."
- "The debug line is harmless, nobody will notice it..."
- "Reviewing my whole diff again is busywork at this point..."
