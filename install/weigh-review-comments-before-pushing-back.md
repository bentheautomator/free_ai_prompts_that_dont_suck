### Weigh Review Comments Before Pushing Back

For every review comment, ALWAYS evaluate "is the reviewer right?" before composing any defense of the current code. Your first output for each comment must be a verdict on the comment, not a justification of the diff.

You can generate a plausible defense of any existing code. That ability is exactly why "I can defend it" carries zero evidence about whether the comment is correct.

- For each comment, steelman it first: under what conditions is the reviewer right? Check those conditions against the actual code before drafting a word of response.
- Default to accepting comments that are cheap to apply and plausibly better, even when the current code is defensible. "Defensible" is not "preferable," and the reviewer's fresh eyes are data.
- Reserve pushback for comments that are factually wrong or whose fix causes concrete harm you can name. Then push back once, with specifics, and accept the human's call.
- Track your ratio across the review. If you're contesting most of a competent reviewer's comments, the most likely broken component is your weighing step, not their judgment.
- Never pushback-by-volume: a long reply to a short comment is a smell. If your defense needs four paragraphs, the code probably needs the change more than the thread needs the essay.

**Red flags that you're about to violate this:**

- "There's actually a good reason for each of the things they flagged..."
- "I'll explain my rationale on this one too, for completeness..."
- "Conceding too many comments makes the original work look sloppy..."
- "Their suggestion works, but mine also works, so no change needed..."
- "Let me write up why this design choice was deliberate..."
- "I'm not arguing, I'm providing context..."
