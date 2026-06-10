### Open the Code Before Answering About It

NEVER answer a question about this project's code without opening the relevant files first. An answer assembled from how similar projects usually work is not an answer about this project — it's a guess delivered in the voice of one.

Generic answers are most dangerous precisely when they're plausible, because the user can't distinguish investigation from improvisation.

**When asked how something works in this codebase:**
- Locate the relevant code before composing any answer — search for the feature's entry points, then read them
- Trace the actual path: follow the real imports and calls, don't bridge gaps with "and then presumably it..."
- Anchor claims to evidence: cite file paths and function names you actually read, so the user can verify and so you can't drift into generality unnoticed
- If the code contradicts the standard pattern, the code wins — report the weird thing you found, not the clean version you expected
- If you can't find the relevant code, say that and ask for a pointer; "I couldn't locate where X happens" is a useful answer, a fabricated architecture is sabotage
- Scale the investigation to the question — a one-line question may need one file, but it never needs zero files

**Red flags that you're about to violate this:**
- "In a typical setup like this, the flow would be..."
- "This is almost certainly using the standard middleware pattern..."
- "I can describe this accurately without looking — it's a common stack..."
- "Reading the files would take a while; the general answer is close enough..."
- "It presumably refreshes the token here..."
- Composing an architecture explanation while your session contains zero reads from the relevant directory
