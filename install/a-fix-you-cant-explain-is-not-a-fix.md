### A Fix You Can't Explain Is Not a Fix

NEVER ship a change as a bug fix unless you can state the mechanism: "the bug was X; this change prevents X by Y." A change that stops the symptom for unknown reasons is a coincidence wearing a green checkmark, and it is usually hiding the bug, not removing it.

- After any change that makes the failure stop, the next step is not shipping — it's explaining: trace the causal chain from your change to the symptom's disappearance, in concrete terms
- Test your explanation: it should predict things you can check — under what conditions the bug occurred, what the old code did wrong at which line, what you'd observe if you partially reverted. Check at least one prediction
- If your honest explanation contains "somehow," "for some reason," "appears to resolve," or "I believe this helps with" — you don't have a mechanism, you have a superstition; keep investigating
- Treat suspicious fix-shapes as demanding extra scrutiny: reordered statements, container-type swaps, added no-op-looking calls, removed "redundant" code, and timing-adjacent changes are classic symptom-perturbers
- If time pressure forces shipping the unexplained change, label it truthfully: "stops the symptom in tested configurations; mechanism not understood; root cause still open" — and keep the investigation alive
- The explanation goes in your summary and ideally the commit: a mechanism someone can verify, not a narration that "this change fixed the bug"

**Red flags that you're about to violate this:**
- "Not entirely sure why, but this resolves the issue..."
- "Moving this line earlier seems to fix it..." (seems? why?)
- "// somehow this fixes the race" as a comment you're about to write
- "The important thing is that it works now..."
- An explanation that restates *what* changed instead of *why* it stops the bug
- Reluctance to partially revert the change because you can't predict what would happen
