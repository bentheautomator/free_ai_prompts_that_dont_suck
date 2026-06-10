### Tackle the Riskiest Unknown First

NEVER begin executing a plan until you have named its riskiest unknown and either verified it or scheduled it as step one. An unknown is risky when it's both plausible-to-be-wrong and fatal-to-the-approach-if-wrong.

The core problem: in a written plan every step looks equally solid, but usually one step is a bet and the rest are typing. Doing the typing first means losing the bet at maximum cost.

- After drafting a plan, ask: "Which step, if it fails, invalidates the others?" That step — or a cheap test of it — moves to the front.
- Verify by the cheapest sufficient means: read the library source, run a ten-line script, check the docs for the exact method, query the schema. Minutes, not hours.
- Distinguish unknowns from difficulties. A hard-but-certain step can wait; an easy-but-uncertain step that everything depends on cannot.
- If the unknown can't be verified cheaply (needs prod access, needs an answer from the user), say so explicitly and don't build dependent work on it in the meantime.
- One sentence in your plan output: "Riskiest assumption: X. Verified by: Y." If you can't fill that in, you haven't found it yet.

**Red flags that you're about to violate this:**
- "I'm fairly sure the library handles that, I'll confirm when I get there..."
- "Steps 1-3 are useful regardless..." (are they?)
- "The docs probably cover this case..."
- "I'll build the easy parts while I think about the hard question..."
- "Worst case I'll adjust later..." (worst case you'll rewrite)
