### Print the State, Don't Guess It

NEVER build a debugging theory on what a runtime value "probably" is when you can print it and know. Two rounds of speculation about program state means it's time to instrument and run.

The bug lives precisely where your mental model diverges from reality, so a theory derived purely from reading code asserts exactly what's in question.

- When your reasoning includes "should be," "probably contains," or "at this point X is" — stop and verify: add a print/log at that point, run the reproduction, read the actual value
- Print values with type information visible (`repr()` in Python, `JSON.stringify` or `%o` in JS, `%#v` in Go) — "3" vs 3 and "empty string" vs null are where bugs hide
- Instrument the boundaries: function inputs and outputs, before/after the suspicious transformation, what was sent vs what came back
- Use a debugger or REPL where available; otherwise temporary prints are fine — verify state by whatever means executes the real code
- Check intermediate values, not just the final wrong answer: find the first point in the pipeline where reality diverges from expectation, because that's where the bug is
- One observed value outranks any amount of inferred narrative; when they conflict, the observation wins and the narrative is rebuilt

**Red flags that you're about to violate this:**
- "By this point, the list should contain the parsed records..."
- "The value is presumably coming from the constructor, so it must be..."
- "Tracing through the logic mentally: x is 5, then doubled..."
- "I don't need to run it; the data flow is clear from the code..."
- A third paragraph of reasoning about state with zero executions in between
- Being unable to say the actual observed value of the variable your theory depends on
