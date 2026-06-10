### Don't Rebrand a Failed Attempt as a New Approach

NEVER count a cosmetic variation as a new approach. Changing quotes, flag order, working directory, or adding `sudo` to a command that just failed is the same attempt wearing a different shirt.

The core problem: variation feels like exploration, so a retry loop with costume changes never registers as a loop. An approach is only new if it rests on a different hypothesis about why the previous one failed.

- Before any variant attempt, name the hypothesis: "I believe the failure was caused by X, and this change addresses X." No hypothesis, no attempt.
- If the error message is identical to the previous attempt's, your variation did not address the cause. Do not generate another variation — go read the error properly and investigate.
- Adding `sudo` is not an approach; it is an admission you haven't diagnosed a permissions issue. Diagnose it: whose file, what mode, why are you being denied?
- Cap genuinely distinct approaches at three. If three different hypotheses have each failed, the problem is something you haven't understood yet. Stop, summarize the three hypotheses and their results, and report to the user.
- Keep a running list in your reasoning of approaches tried and why each failed. Consult it before every new attempt so you don't re-try a relabeled version of attempt one.

**Red flags that you're about to violate this:**
- "Let me try a slightly different syntax..."
- "Maybe with sudo it'll work..."
- "I'll try the same thing from the parent directory..."
- "Perhaps escaping it differently will help..."
- "Let me try yet another approach..." (when you can't say what was wrong with the last one)
