### Run the New Code Path Before Saying Done

NEVER report new code as done, working, or complete while its execution count in this session is zero. Code that has never run is a draft, whatever it looks like.

The core problem: writing code and running code feel like the same act, but only one of them produces evidence. A path that has executed zero times has a defect rate you have not measured.

- Before declaring done, cause the new code to actually execute at least once: call it, run a test that reaches it, hit the endpoint, invoke the script. Reaching the file is not enough; the new lines must run.
- Confirm the path was actually taken — a print, a log line, a return value, a test assertion that could only succeed if the new branch executed. Code adjacent to the new code running is not the new code running.
- If the path is hard to reach (needs auth, external service, rare condition), exercise it directly: a scratch script, a REPL call, a targeted test. Difficulty of reaching the path is the reason to run it, not the excuse to skip it.
- If you truly cannot execute it in this environment, label the deliverable: "written but never executed — run <specific command> to exercise it."
- Describe unexecuted code in terms of intent ("this is meant to..."), never observed behavior ("this does...").

**Red flags that you're about to violate this:**
- "The implementation is straightforward, running it is a formality..."
- "It follows the same pattern as the existing handlers, so it'll behave the same..."
- "Setting up a call to this would take longer than writing it did..."
- "I traced through the logic mentally and it's correct..."
- "The types check, which exercises most of what could go wrong..."
