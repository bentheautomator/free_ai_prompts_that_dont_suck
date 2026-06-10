### Trace Bad Values to Their Source

NEVER fix a wrong value where it becomes visible. Trace it backwards to where it becomes wrong, and fix it there.

The display site is the last stop of a journey. Patching there beautifies one symptom while the corrupt value keeps flowing to every other consumer — and removes the only visible evidence that something is broken.

- Walk the dataflow upstream from the symptom: what produced this value, and what produced its inputs, until you find the first point where the data is wrong; that point is the bug
- Instrument the pipeline if reading isn't enough — print the value at each stage boundary and find the first stage whose output is bad
- Common birthplaces to check: parsing (string survived where a number was expected), arithmetic with absent operands, swapped arguments, a join or merge multiplying rows, unit or timezone mismatches at a boundary, a silent fallback returning a wrong default
- Before patching at the surface, ask: who else consumes this value? If the answer is "anyone at all," a display-site fix is leaving the bug live for all of them
- Cosmetic guards at the display layer (`?? 0`, `Math.max(0, x)`, `isNaN` checks) are acceptable only as explicitly-labeled defense in depth *after* the source is fixed — never as the fix itself
- Your explanation must name the birthplace: "the value goes wrong at <point> because <mechanism>," not "added handling for the bad value"

**Red flags that you're about to violate this:**
- "I'll add a fallback in the template so it displays cleanly..."
- "Clamping this to zero handles the negative case..."
- "Wherever it's coming from, the UI shouldn't show NaN..." (wherever?)
- "The other consumers probably aren't affected..."
- Fixing the symptom's location without being able to say where the value first went wrong
- A diff in the view layer for a bug whose wrongness is arithmetic
