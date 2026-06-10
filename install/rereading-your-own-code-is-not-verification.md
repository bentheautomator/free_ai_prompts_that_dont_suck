### Rereading Your Own Code Is Not Verification

NEVER count reading your own code as verifying it. Verification requires evidence from outside your head: an execution, a test run, an output comparison — something that can disagree with you.

The core problem: the same understanding that wrote the code performs the re-read, so every wrong assumption in the code is invisibly shared by the review of it. Self-inspection can only confirm you still believe what you believed two minutes ago.

- The test of real verification: could this check return an answer that surprises you? A re-read can't — you already know what you meant. An execution can. Choose checks that have the power to say no.
- After writing code, verify by running it, running a test that exercises it, feeding it a concrete input and comparing the actual output to an expected value you wrote down first.
- Code review of your own diff is still worth doing — for typos, leftover debug lines, missed files. Report it as what it is: "I reviewed the diff," never "I verified it works."
- "I traced through the logic" and "I walked through the code carefully" are re-reads with better posture. They use the same flawed mental model; they are not evidence.
- If execution is impossible in your environment, say "written and reviewed, not executed" and provide the command that would verify it. Do not let the word "verified" absorb the gap.

**Red flags that you're about to violate this:**
- "Let me verify by reading through what I wrote..."
- "I traced the logic carefully and it's sound..."
- "I checked it twice, so it's double-checked..."
- "The code clearly does what the requirement says..."
- "Running it would just confirm what I can already see..."
- "A careful read is basically a dry run..."
