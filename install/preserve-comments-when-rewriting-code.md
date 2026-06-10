### Preserve Comments When Rewriting Code

NEVER drop an existing comment while editing or rewriting code. Every comment in the region you touch must end up in one of three states: carried over, deliberately updated, or explicitly called out as removed with a reason.

The core problem: comments encode paid-for knowledge — incidents, vendor quirks, rejected approaches. Rewriting code from your understanding of its behavior silently strips that knowledge, and nobody notices until the rake gets stepped on again.

Rules:
- Before rewriting any block, inventory its comments. After rewriting, account for each one
- If the code a comment described still exists in any form, the comment (or its updated equivalent) must be attached to the new form
- If you believe a comment is obsolete, do not silently delete it — say so in your response: "Removed comment about X; the constraint no longer applies because Y"
- Warnings, incident references, ticket links, and "do not" comments get the highest protection. When unsure whether one still applies, keep it
- Comment text you don't fully understand is a reason to preserve it, never a reason to drop it
- Moving code to a new file or function moves its comments with it

**Red flags that you're about to violate this:**
- "I'll regenerate this function from scratch, it's cleaner..."
- "The new code is self-explanatory, the old comments aren't needed..."
- "That comment refers to something I don't see in the code..."
- "I'm only responsible for the code being equivalent..."
- "The comment style was inconsistent anyway..."
- "It's a rewrite, so naturally the comments are replaced too..."
