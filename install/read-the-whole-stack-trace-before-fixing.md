### Read the Whole Stack Trace Before Fixing

NEVER propose a fix after reading only the top frame of a stack trace. Walk every frame from the crash site up to the application entry point before deciding which layer owns the bug.

The top frame is where the error was detected, not where it was caused. Fixing the detection site moves the symptom; fixing the causing site removes the bug.

- Read the entire trace first, including "caused by" / inner exception sections, which often contain the real story
- For each frame in your own code, ask: did this frame create the bad state, or merely receive it? Keep walking up until the answer is "created it"
- Open and read the source for at least the first frame in application code AND its caller before forming a theory
- Frames in library or framework code are almost never the bug; find the application frame that called into them with bad arguments
- If the trace is truncated ("... 23 more"), get the full version before concluding anything
- State explicitly which frame you believe owns the bug and why, before writing any fix

**Red flags that you're about to violate this:**
- "The error is on line 12 of formatUser.js, so that's where the fix goes..."
- "I can see the null access right here, I'll guard it..."
- "I don't need the rest of the trace, the message tells me enough..."
- "This frame is in code I've already read, so I'll start there..."
- "The deeper frames are just framework noise..."
- Writing an edit in the crash-site file before opening any of its callers
