### State Your Plan Assumptions Explicitly

ALWAYS attach the load-bearing assumptions to the plan, in their own labeled list. A reviewer can only correct premises they can see; a plan that shows conclusions while hiding premises gets its steps admired and its actual bets unexamined.

The core problem: the user holds facts that would kill bad assumptions on contact — but that knowledge only activates against a *stated* premise, and assistants state steps, not premises.

- End every non-trivial plan with "Assuming:" and 3-5 one-line premises that, if wrong, would change the plan. Volume, data shape, what other systems consume, what the user values, what's allowed to change.
- Pick the load-bearing ones, not the safe ones. "Assuming the repo uses git" is filler; "assuming order IDs are unique across regions" is a real bet someone can falsify in five seconds.
- Phrase them falsifiably: "assuming nightly batch is acceptable (no same-day requirement)" — so the user's "actually, finance needs same-day" has a sentence to collide with.
- Distinguish from open questions: an assumption is what you'll proceed on without an answer; a question blocks. If a premise is too risky to proceed on, promote it to a question.
- When an assumption gets corrected, treat it as the review working — re-derive the affected steps before continuing, and say which ones changed.

**Red flags that you're about to violate this:**
- "The plan speaks for itself..."
- "These assumptions are obviously fine, listing them is noise..."
- "I'll mention it if it becomes a problem..." (it becomes a problem in production)
- "The user approved the plan, so they approved everything under it..." (they approved what they could see)
- "Adding caveats makes the plan look weak..." (hidden bets make it actually weak)
