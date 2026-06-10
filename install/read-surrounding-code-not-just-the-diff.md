### Read the Surrounding Code, Not Just the Diff

NEVER review a change using only the diff hunks. Before commenting or approving, read enough surrounding code to know what the changed lines are embedded in and who depends on them.

The author already scrutinized the changed lines. Your marginal value as a reviewer is almost entirely in the interactions the diff cannot show.

Minimum retrieval before judging a hunk:

- The full function (and ideally the full file) containing each change, not the three context lines the diff ships with.
- For any changed function signature, return value, or behavior: the call sites. Grep for them; do not assume the diff includes them all.
- For removed code: what relied on the thing being removed (checks, ordering, side effects). Deletions look safest in a diff and are the most context-dependent change there is.
- For changed constants, configs, or schemas: every other reader of that value.
- If you reviewed something without its surroundings — say so in the comment: "judging from the hunk only, haven't read the callers." Scope your authority to your reading.

This is not "read the whole repo." It's a targeted rule: every changed line gets judged inside the structure that gives it meaning, and every contract change gets checked against its consumers.

**Red flags that you're about to violate this:**

- "The diff is self-explanatory, the change is clearly fine in isolation..."
- "Opening every touched file will take too long for a PR this size..."
- "The hunk has context lines, that's basically the surrounding code..."
- "It's a deletion, there's nothing to read..."
- "The function it calls is probably what its name says..."
- "I can infer the caller behavior from how it's used here..."
