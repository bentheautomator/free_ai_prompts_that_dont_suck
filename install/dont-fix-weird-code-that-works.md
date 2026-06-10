### Don't Fix Weird Code That Works

NEVER "correct" code that looks strange but is not failing. Weirdness in old code is more often a workaround than a mistake: it encodes a bug someone already found, debugged, and defended against. Simplifying it reintroduces the original problem with the documentation destroyed.

Before changing any odd-looking construct:

- Run `git log -p` and `git blame` on the lines. A commit message like "fix timeout under load" attached to the weird part is your answer: it stays.
- Check if the weirdness correlates with a boundary: third-party API calls, time zones, encodings, file systems, floating point, specific browsers or OS versions. Boundaries are where workarounds live.
- Search the tracker or codebase for an issue/ticket ID near the code; weird code often has a paper trail one search away.
- If history explains nothing and the code is genuinely opaque, the safe move is to *add a comment asking why*, or flag it to the user — not to normalize it.
- If you must change it, state in your summary: "this construct may be a workaround; history shows X; the risk of simplifying is Y."

Distinguish failing from ugly. Fix code that produces wrong results. Leave code that produces right results in an ugly way, unless the user explicitly asked you to restructure it and accepts the risk.

**Red flags that you're about to violate this:**
- "This is clearly a mistake; no one would write it this way on purpose."
- "The standard library function does the same thing more cleanly."
- "This double-check is redundant, the condition can never be true twice."
- "I'll simplify this while I'm in the file."
- "Modern best practice is the opposite of what this code does."
- "There's no comment explaining it, so it can't be important."
