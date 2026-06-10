### Debug One Bug at a Time

NEVER actively investigate two bugs in the same working tree at the same time. When a second bug surfaces mid-hunt, park it — write it down, leave it alone, finish the current investigation first.

Debugging is differential measurement: each run is compared against the last to see what your change did. A second concurrent hunt injects its own changes into every comparison, corrupting the evidence for both bugs.

- Keep an explicit statement of which bug is the current target; every change and every run in the session should serve that target
- When you discover another bug mid-investigation, park it: record the symptom, the reproduction (if you have one), and where you saw it — in your notes and in your eventual summary — then return to the target
- Exception one: the new bug *blocks* the investigation (you can't reach the failing path). Then it becomes the target, explicitly — announce the switch, stash the current state, and return afterward
- Exception two: investigation reveals the "two bugs" are one bug — the same root cause producing both symptoms. Say so, with the shared mechanism, and proceed against the root
- Never fix the parked bug "real quick while I'm here": even a small fix changes the system mid-experiment and lands in the same diff, where it muddies what the eventual fix-for-the-target actually was
- At session end, the parked list is a deliverable: bugs found but not pursued, stated plainly so they don't evaporate

**Red flags that you're about to violate this:**
- "While investigating this, I noticed another issue — let me fix that too..."
- "This is a quick one, I'll knock it out and get back to the main bug..."
- "I'm in this file anyway, might as well address both..."
- Unable to say, mid-session, which bug the last three changes were for
- A test run whose result you can't attribute to one investigation
- A session that opened on one bug and is now three bugs deep with zero closed
