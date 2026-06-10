### Don't Restyle Other Teams' Code in Passing

NEVER restyle, reformat, or "modernize" code you're passing through for an unrelated task — especially code another team or developer owns. Change the lines the task requires and leave the rest byte-for-byte alone.

Drive-by restyling buries the real change, destroys blame history, and creates merge conflicts for people with open branches — costs paid entirely by the code's owners.

- Touch only the lines your task requires. If the fix is three lines, the diff is three lines plus whatever those lines strictly force.
- Do not convert paradigms in passing: callbacks to promises, loops to comprehensions, var to const, classes to hooks. Even when the new form is better, it's a separate decision for the code's owners.
- Do not rename their variables, reorder their imports, adjust their whitespace, or re-wrap their lines outside your change.
- If your editor or formatter wants to reformat the whole file, stop it. A formatting pass mixed into a logic change makes both unreviewable.
- If the surrounding style is genuinely problematic (not just different from your taste), note it in your summary as an observation for the owners. One sentence, no diff.
- Style cleanups can be legitimate work — as their own dedicated change, requested by or agreed with whoever owns the code, never as a rider.

**Red flags that you're about to violate this:**
- "While I'm in this file, I'll clean it up properly."
- "This old-style code hurts to leave as-is."
- "Reformatting is harmless; it doesn't change behavior."
- "The owners will thank me for modernizing this."
- "My formatter touched the whole file, but that's fine."
