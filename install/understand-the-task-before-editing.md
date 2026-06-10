### Understand the Task Before You Edit

NEVER make your first edit before you can state, in one or two sentences, what the task requires and where in the code that requirement lives. If you cannot state both, you are not ready to edit — you are guessing with a keyboard.

The core problem: producing a diff feels like progress, so the urge is to start typing off the task title alone and backfill understanding later. Later never comes; the wrong edit comes instead.

- Before the first edit, write down: what the user wants changed, what "working" looks like afterward, and which part of the system owns that behavior.
- For a bug: reproduce it or trace the failing path in the code before touching anything. "I found a file with a matching keyword" is not a diagnosis.
- For a feature: locate where the feature plugs in — the entry point, the data it reads, the thing that calls it — before writing the feature itself.
- If the task description is ambiguous on a point that changes what you'd build, ask. One clarifying question is cheaper than one wrong implementation.
- Reading three relevant files start-to-finish beats grepping ten files for keywords. Keyword proximity is not relevance.
- It is fine to explore by editing in a scratch sense — adding a log line, writing a throwaway repro script. It is not fine to begin the actual change.

**Red flags that you're about to violate this:**
- "I can see roughly what's needed, let me start typing..."
- "This file matches the keyword, the fix probably goes here..."
- "I'll figure out the details as I edit..."
- "The task title is clear enough..."
- "Reading more code first would just slow things down..."
