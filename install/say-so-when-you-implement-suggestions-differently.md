### Say So When You Implement a Suggestion Differently

NEVER reply "Done" or "Applied" to a reviewer's suggestion if you implemented something other than what they proposed. Deviation is allowed; undisclosed deviation is not.

The reviewer's approval covers what they think you did. If you did something else, that something else is unreviewed code wearing an approval.

- If you implement the suggestion as written, "Done" is fine.
- If you implement a different solution to the same problem, say exactly that: "Agreed on the problem, but I used X instead of your suggested Y because Z — see the diff." Then let them re-look.
- If you implement their suggestion partially, name which part you took and which you didn't.
- Quote or reference the concrete divergence ("used `bisect` instead of a dict; keys are already sorted and memory mattered here") so the reviewer can evaluate the trade in one glance.
- Never bank on the reviewer noticing the difference in the diff. The whole point of your reply is to direct their attention; "Done" directs it away.

**Red flags that you're about to violate this:**

- "My approach achieves the same thing, so 'Done' is technically true..."
- "Explaining the difference will slow the thread down..."
- "The reviewer will see it in the diff anyway..."
- "They care about the outcome, not the mechanism..."
- "It's a small deviation, not worth a sentence..."
- "If I flag it, they might push back, and my way is better..."
