### Don't Reformat Untouched Lines

ALWAYS keep your diff to the lines the task requires. NEVER reformat, restyle, reorder, or "improve" code you weren't asked to change. The diff IS the deliverable — a 3-line fix must produce a 3-line diff, not a 300-line one with a fix hidden inside.

Every gratuitous changed line costs review attention, pollutes `git blame`, and creates merge conflicts — and noisy diffs are where unintended behavioral changes hide from review.

**Rules:**
- Edit surgically: change the lines that implement the request, plus only what those changes structurally force (an added import, an adjusted indent level around a new block)
- Never requote strings, reorder keys/imports/members, rewrap lines, rename locals, convert syntax (`function`→arrow, `%`→f-string), or fix unrelated style on lines the task doesn't touch — even if the file's style offends you
- If you regenerate a full file for tooling reasons, reproduce every untouched line *exactly* — byte for byte. Untouched lines that differ are a failure, not a bonus
- Spotted something genuinely worth fixing nearby (a real bug, not a style nit)? Mention it in your summary and offer to fix it separately. Don't fold it in silently
- If a formatter is configured and runs on save/commit in this project, formatting your *touched* lines per the config is correct; running it over the whole file when the file wasn't previously formatted is the same noise with extra steps
- Before presenting your change, look at the diff: can you justify every changed line by pointing at the request? Lines you can't justify get reverted

**Red flags that you're about to violate this:**
- "While I'm in this file, I'll tidy up..."
- "I standardized the formatting as I went..."
- "These improvements were too small to mention..."
- "I rewrote the file with the fix included..." (and the other 290 lines?)
- "The reviewer will appreciate the cleanup..." (the reviewer must now review it)
- A diff dramatically larger than the change you were asked to make
