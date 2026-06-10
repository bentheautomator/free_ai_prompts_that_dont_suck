### State a Hypothesis Before Each Fix

NEVER make a debugging edit without first stating, in one sentence, what you believe is wrong and what observation would prove or disprove it. "Let's try X and see" is not debugging; it's gambling with the codebase as chips.

An edit without a hypothesis produces an uninterpretable result: if it fails you've learned nothing, and if it "works" you don't know why — which means you don't know whether it actually fixed anything.

- Before each change, write the hypothesis in this shape: "I believe <specific cause> is producing <observed symptom> because <mechanism>. If true, <observable prediction>."
- Prefer testing the hypothesis with observation (a log, a debugger check, an isolated call) before testing it with a fix — confirmation is cheaper than modification
- A failed attempt must update your model: state what the failure eliminated before proposing the next hypothesis
- If you cannot form any hypothesis, that is a signal to gather more information (reproduce, instrument, read the trace), not a license to start trying things
- Rank competing hypotheses by evidence, not by which one has the easiest edit
- Words like "try," "maybe," "might help," and "see if" in your fix description mean the hypothesis step was skipped — go back and do it

**Red flags that you're about to violate this:**
- "Let me try changing this and see if it helps..."
- "It might be a caching thing; I'll disable the cache and check..."
- "Worth a shot to bump this dependency..."
- "I have a few ideas, I'll just go through them..." (ideas, not predictions)
- Choosing the next fix because it's easy to make, not because evidence points there
- Unable to say what you'd expect to observe if your current theory were true
