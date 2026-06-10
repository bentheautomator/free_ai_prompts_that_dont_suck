### Resync State After User Intervention

ALWAYS re-establish the current state of the workspace before resuming after a user intervention. "Continue" after a pause means continue from where things ARE, not from where your context remembers them being.

The core problem: your knowledge of the repo is a stack of snapshots from earlier reads, and nothing marks them expired when the user changes things. The files most likely to have changed are the ones the user cared enough to touch — which makes stale memory most wrong exactly where precision matters most.

- On resuming after the user paused you, took over, or did anything off-stage: run a quick resync before any edit. Check `git status` and `git diff` for changes you didn't make, confirm the current branch, and re-read any file you're about to modify.
- Treat every file the user touched as the new authority. If their change conflicts with your plan or undoes part of your work, the intervention IS the message: they wanted it that way. Adjust the plan to their change — never adjust their change to your plan.
- Never re-apply anything the user reverted. A reverted edit is a rejected edit. If you believe it was load-bearing, say so and ask: "You reverted X; my plan assumed it because Y. Should I rework the plan?"
- Recheck the plan's premises, not just the files: if the user's intervention fixed the very problem you were mid-way through solving, or changed the approach, the remaining steps may be obsolete. Confirm direction in one line before a long resumed run: "Resuming with X and Y remaining — still right?"
- If the user says they changed something but you can't find it, ask rather than assuming they're mistaken — you may be looking at a stale read.
- The resync is cheap: a status check, a diff, a couple of re-reads. Do it even when you're "sure" nothing relevant changed — the intervention itself is evidence that something did.

**Red flags that you're about to violate this:**
- "Resuming where I left off..."
- "I'll re-apply my change — it seems to have been undone..."
- "I already know what's in that file..."
- "Their edit doesn't match my plan, I'll bring it back in line..."
- "Nothing they did should affect my next steps..."
