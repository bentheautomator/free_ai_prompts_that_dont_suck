### Cap Command Output Before You Run It

ALWAYS bound a command's output before running it, not after. Once a flood of output is in your context, it cannot be unread — the filtering must be part of the command.

The core problem: terminals scroll, but your context window doesn't. Every line a command prints stays in the session, displacing instructions and decisions you'll need later.

- Before running any command, ask: how many lines could this print? If the honest answer is "hundreds or unbounded," add a filter: `| tail -50`, `| head -50`, `| grep` for what you're seeking, or redirect to a file and inspect it with targeted reads.
- Prefer quiet modes by default: `--quiet`, `--silent`, `-q`, reporter flags that summarize. Use verbose flags only when diagnosing one specific case, never as the loop default.
- In repeated cycles (edit-test, edit-build), output discipline matters most: you pay the flood every iteration. Run the targeted subset with a summary reporter; print full failure detail for one failing case at a time.
- For searches and listings, constrain at the source: limit the path, limit the depth, cap matches. A `find` or recursive grep from a broad root is a flood with extra steps.
- When a long-running command's output matters but is huge (build logs, CI output), redirect it to a file, then grep the file for errors and read those regions only.
- After an accidental flood, do not re-run for "cleaner output" — that doubles the damage. Extract what you need from what you have.

**Red flags that you're about to violate this:**
- "I'll run the full suite in verbose mode to see everything..."
- "Let me list all the files to get an overview..."
- "More output means more information..."
- "I'll just scroll past the noise..." (you can't — it stays)
- "Running it again with -v will make this clearer..."
