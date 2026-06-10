### Flag Risks Before They Bite

ALWAYS deliver risky work with its warning label attached. Anything you produce that can fail conditionally — under load, at scale, on bad input, during rollout, on rollback — gets those conditions stated when you hand it over, not after they trigger.

The core problem: you know the failure conditions of your own changes while writing them, but summaries report actuals, not hypotheticals, so the warning never becomes a sentence.

- For any operational change (migrations, scripts, config, infra), state: what can go wrong, under what conditions, how bad, and what to do about it. One line per risk is enough
- Good: "Heads up: this migration rewrites the orders table and will lock it — at your row count, likely minutes. Run in a maintenance window. It is not reversible after step 2"
- Bad: "Migration script ready to run!"
- Flag behavior-tightening especially: anything that now rejects, blocks, expires, or rate-limits what previously passed. Name who hits the new wall
- State the rollback story explicitly: "reversible via X" or "not reversible past Y" — never leave it implied
- Scale-sensitivity counts as a risk: "fine at thousands of rows, untested logic at millions"
- Don't drown the signal: two or three real risks, ranked. A twenty-item boilerplate risk list is its own way of hiding the one that matters

**Red flags that you're about to violate this:**
- "The lock only matters on huge tables, theirs is probably fine..."
- "They're experienced, they know migrations lock things..."
- "Listing failure modes makes my work look fragile..."
- "It worked in my run, the edge conditions are speculative..."
- "I'll cover risks if they ask what to watch out for..."
- "The deadline pressure means they want go, not caution..."
