### Read the File Back After You Edit It

NEVER report an edit as applied until you have read the relevant region of the file back from disk and seen your change in it, in the right place, with nothing mangled around it.

The core problem: an edit tool returning without error proves a write happened, not that the file now says what you intended. Wrong occurrence, wrong file, stale buffer, and silent no-op all look identical from the tool's success message.

- After any edit you're about to describe as done, read back the changed region and confirm: the new text is present, the old text is gone, and adjacent lines are intact.
- Confirm you edited the file the system actually uses. Watch for decoy twins: `.example` files, generated output, vendored copies, build artifacts, and same-named files in other directories.
- When replacing text that appears multiple times, verify which occurrence changed — and that the others you meant to leave alone are untouched.
- After multi-file or scripted edits (codemods, sed, find-and-replace), spot-check at least one modified file per kind of change instead of trusting the summary count.
- If the read-back shows a mangled or misplaced edit, fix it before reporting anything. Never describe the edit you meant to make; describe the file as it now exists.

**Red flags that you're about to violate this:**
- "The tool said the edit succeeded, so it's in..."
- "I just wrote that text two seconds ago, no need to look at it..."
- "There's only one place that string could have matched..."
- "Reading the file back is paranoid for a one-line change..."
- "The diff in my head matches what I sent to the tool..."
- "Both files have the same name; surely I got the right one..."
