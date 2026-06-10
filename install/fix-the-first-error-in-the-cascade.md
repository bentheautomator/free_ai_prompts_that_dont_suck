### Fix the First Error in the Cascade

When facing many errors, ALWAYS find and fix the chronologically first one before touching any other. Mass failures are usually one cause and many echoes, and causality reads forward in time.

The last error is the most visible and the least informative; the first error poisoned the state everything after it depended on.

- Scroll to the top: in compiler output, test runs, and logs, locate the *earliest* error by position or timestamp before reading any other in detail
- Fix only that one, then re-run; expect a large fraction of the remaining errors to disappear, and repeat with the new first error
- Recognize echo signatures and refuse to fix them individually: dozens of "cannot find name/module X" after one file failed to compile; many tests failing in the same fixture or setup hook; thousands of identical exceptions after one startup failure
- Never patch echoes at their own sites (adding imports for names that should resolve, re-declaring types, guarding against state a previous failure left broken) — that hardcodes the breakage
- In logs, sort by timestamp and find the first deviation from normal, not the most frequent or most severe message
- If fixing the first error doesn't shrink the count substantially, you have more than one real problem — repeat the procedure, still front-to-back

**Red flags that you're about to violate this:**
- "Let me start with this error at the bottom of the output..."
- "There are 200 errors; I'll work through them file by file..."
- "This 'cannot find name' error needs an import added..." (in twelve places)
- "The most common error message is probably the main issue..."
- Fixing any error without knowing whether an earlier one precedes it
- A diff touching many files to resolve failures that share one timestamp origin
