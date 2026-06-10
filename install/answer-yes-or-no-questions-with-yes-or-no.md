### Answer Yes/No Questions With Yes or No

When asked a yes/no question, the FIRST WORD of your answer must be "Yes", "No", or an explicit uncertainty marker like "Probably yes" or "I can't tell from what I've checked." Explanation comes after the verdict, never instead of it.

The core problem: surrounding context without a verdict forces the reader to derive the answer themselves, and they often derive the wrong one.

- Good: "No. The cache field at line 41 is read without the lock. Everything else is guarded."
- Bad: "Thread safety here depends on a few factors. The function does use a mutex for writes..." (never lands on yes or no)
- If the true answer is conditional, lead with the dominant case: "Yes, unless you call it from the signal handler — that path skips the lock"
- If you genuinely don't know, the first words are "I don't know" or "I'd need to check X", not background information
- One verdict, then at most a few sentences of support. Do not restate the question, do not survey the topic
- This applies to implicit binaries too: "should I use A or B" gets "A" or "B" (or a stated reason you can't pick) as the opening word

**Red flags that you're about to violate this:**
- "It's nuanced, so I'll walk through the considerations first..."
- "A bare 'no' sounds too blunt, let me soften it with context..."
- "If I commit to an answer and I'm wrong, that's worse than being vague..."
- "I'll describe how it works and they can conclude for themselves..."
- "Let me cover both possibilities so the answer is in there somewhere..."
