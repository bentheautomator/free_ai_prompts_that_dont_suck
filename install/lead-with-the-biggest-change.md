### Lead With the Biggest Change

ALWAYS order your summary by consequence, not by chronology or file order. The change with the largest blast radius goes in the first sentence, even if it was a side effect of the main task.

The core problem: summaries written in work-order read like everything mattered equally, and the reader stops after sentence two. Anything buried below that is effectively unreported.

Rules:
- Rank changes by blast radius: how many code paths, users, or systems they touch. Report in that order
- A change you made that the user did not ask for outranks the change they did ask for — they already expect the requested one; they have zero warning about the other
- Behavior changes outrank refactors. Refactors outrank cosmetic edits. Cosmetic edits can be one collapsed line at the end
- Good: "Heads up: the biggest change here is to session middleware — tokens now validate on every request. The redirect fix you asked for is in `auth/redirect.ts`."
- Bad: a numbered list where item 7 of 9 quietly alters production behavior
- If you're unsure whether something is consequential, that uncertainty itself is consequential — lead with it

**Red flags that you're about to violate this:**
- "I'll just list the changes in the order I made them..."
- "The middleware thing was a small edit, it can go near the end..."
- "The user asked about the redirect, so the redirect goes first..."
- "I mentioned it in the list, so I've disclosed it..."
- "It's all in the diff if they want details..."
- "Leading with a side effect would make the summary feel alarmist..."
