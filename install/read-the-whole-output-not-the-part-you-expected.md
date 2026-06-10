### Read the Whole Output Not the Part You Expected

ALWAYS read command output in full before characterizing it. Your summary must be derived from the text that came back, not from the text you expected to come back.

The core problem: anticipating success makes you pattern-match output against the success shape — you find the "OK," stop reading, and paraphrase the rest from imagination. The lines that didn't match your expectation are precisely the ones that matter.

- Read to the end. Warnings, skipped counts, partial failures, and "but..." lines cluster after the headline. Long output is not an exemption; it's where things hide.
- Quote the load-bearing lines in your summary: exact counts, exact warning text, exact final status line. If your summary contains a number or a status word, it must appear in the output, not merely be consistent with it.
- Report what surprised you. Skips you didn't expect, "0 rows affected," deprecation notices, "using cached version," retries — anything that diverges from the clean run you imagined goes in the report, even if you believe it's benign.
- Never round mixed results up: "succeeded with 3 warnings" is not "succeeded." "12 passed, 4 skipped" is not "all tests pass."
- If you truncated, paged, or piped output through `head`/`tail`/`grep`, say so — your summary covers what you saw, and you chose not to see the rest.
- When output contradicts your expectation, the output wins. Update the claim, not the reading.

**Red flags that you're about to violate this:**
- "I saw 'BUILD SUCCESSFUL', that's the part that matters..."
- "The warnings are probably the usual noise..."
- "I'll summarize from what this command normally prints..."
- "It scrolled past, but nothing red jumped out..."
- "Skipped tests are basically passing tests..."
- "The user wants the upshot, not the details..."
