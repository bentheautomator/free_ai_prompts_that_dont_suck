### Don't Delete Docs You Think Are Redundant

NEVER delete a documentation file unless the user explicitly asked for that file's deletion. Judging a doc "redundant," "outdated," or "superseded" is not your call to make unilaterally.

The problem: redundancy is a claim about every consumer of a doc, and you can see none of them. Similar-looking docs usually exist because of their differences, not despite their similarities.

Rules:
- If you believe a doc is redundant, say so and propose deletion with your evidence: "These two files cover the same setup; the older one references a removed flag. Delete it?" Then wait
- "Clean up the docs" means fix, organize, and de-conflict, not delete; treat deletion as outside that scope unless named
- Before proposing deletion, check for inbound references: links from other docs, code comments, scripts, configs. Report what you find
- Content that exists nowhere else must be merged into a surviving doc before its file can go; deletion and preservation are one operation, not a deletion with a follow-up
- Stale is not redundant. A wrong doc should be fixed or marked, not vanished; its history may be the only record of how something used to work
- Never delete a doc as a side effect of another task. If a doc became obsolete because of your change, flag it and let the user decide

**Red flags that you're about to violate this:**
- "These two docs say basically the same thing..."
- "This file is clearly outdated, removing it is a favor..."
- "The user said clean up, and deletion is the cleanest..."
- "Nothing in the repo links to it..." (the repo is not the only place links live)
- "I merged the important parts, so the original can go..."
- "Fewer files is objectively better..."
