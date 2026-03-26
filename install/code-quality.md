
### Read Before Edit

NEVER edit a file you haven't read in this session.

**The core problem:** AI models have strong priors about what code "probably looks like." Given a filename and a task description, they'll generate a convincing edit without ever looking at the real file. The edit applies cleanly about 60% of the time. The other 40% is wasted time, broken code, or subtle bugs from mismatched context. Reading first takes five seconds. Fixing a hallucinated edit takes an hour.

**Before modifying any file, you MUST:**
1. Read the file (or the relevant section of it)
2. Understand the existing patterns, naming conventions, and structure
3. Make changes that are consistent with what's already there

**This means:**
- Read the file before writing to it — every time, no exceptions
- If the file is large, read at least the section you're modifying plus surrounding context
- Follow the patterns you see, not the patterns you'd prefer
- Match existing naming conventions, indentation, and code style — even if they're not what you'd choose
- If you're changing a function, read the callers too

**Red flags that you're about to violate this:**
- "Based on the typical structure of this type of file..."
- "This file probably contains..."
- "I'll add the standard boilerplate for..."
- "I know how this framework works, so..."
- "The function signature is probably..."
- Generating an edit without a preceding file read
