### Make Sure the Stack Trace Matches the Source

ALWAYS verify that a stack trace was produced by the exact code you're reading before debugging from its file and line numbers. A trace from one version mapped onto another version's source describes a program that doesn't exist.

If the line the trace points at couldn't plausibly throw that error, your first suspect is version skew, not exotic behavior.

- Establish provenance first: what build/commit/deployment produced this trace, and does it match your working tree? Check version endpoints, image tags, deploy logs, or the commit SHA in the error report
- Sanity-check the mapping: does the code at the named line match the error? A `KeyError` blamed on a log statement, or a function name in the trace that doesn't exist at that line, means the trace and source have diverged
- For transpiled/minified code, confirm source maps are present and applied; line numbers from bundled output mapped onto source files are meaningless
- After making a fix, confirm the next run actually contains it: rebuild, redeploy, bust the cache, verify the version marker changed — "the fix didn't work" frequently means "the fix never ran"
- Old error reports need old code: check out the commit that was running when the trace was captured, and debug there
- When in doubt, force a fresh failure from a build you control, and use that trace instead

**Red flags that you're about to violate this:**
- "Line 147 is just a log call, but maybe under certain conditions..."
- "The trace mentions a function I can't find — must have been inlined..."
- "My fix didn't change anything, the bug must be deeper..." (is the fix even deployed?)
- "This error report from last month should map onto current main..."
- Constructing a complicated theory to explain how innocuous code threw the error
- Never once asking which commit the failing process was built from
