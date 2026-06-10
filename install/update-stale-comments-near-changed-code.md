### Update Stale Comments Near Changed Code

ALWAYS re-read the comments above and inside any block you modify, and fix every one your edit just falsified. The edit and the comment update are one change, not two.

The core problem: editing only the lines that implement behavior leaves nearby lines that *describe* behavior telling yesterday's story, and future readers cannot tell which one to believe.

Rules:
- After every edit, scan upward to the nearest comment and outward to the function's header comment or docstring. Ask of each: "is this still true after what I just did?"
- Comments mentioning specific values (counts, timeouts, limits, formats) are the most likely casualties — if you changed a number, search the surrounding comments for the old number
- Check comments at the call-site level too: if you changed what a function returns or throws, comments at its callers (`// never returns null`) may now be false
- Fix falsified comments in the same edit. Never note them for later
- If a comment was *already* wrong before your change, flag it — don't silently leave known-false prose because you didn't write it
- Deleting a falsified comment is acceptable only if the why it documented no longer exists; otherwise update it

**Red flags that you're about to violate this:**
- "My change is just to the logic, the comment is out of scope..."
- "I'm keeping the diff minimal..."
- "The comment is close enough to still be roughly true..."
- "Whoever reads the code will see what it really does..."
- "I didn't write that comment, so it's not mine to change..."
- "The old value in the comment is a minor detail..."
