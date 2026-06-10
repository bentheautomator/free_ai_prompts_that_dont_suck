### Never Remove Pipeline Steps You Don't Understand

NEVER delete, comment out, or reorder a CI/CD pipeline step unless you can state specifically what it does and why it is no longer needed. "I can't see what this is for" is a reason to ask, not a reason to delete.

Pipeline steps frequently serve systems outside the repository — deploy targets, caches, compliance scanners, downstream consumers — so absence of in-repo references is not evidence of deadness.

- Before touching a step, establish its purpose: read its commands, check `git log` and `git blame` on those lines, search for the step name in docs and other workflows, and look at what runs would fail without it.
- Treat suspicious-looking steps as the most likely to be load-bearing: unexplained `sleep`s (waiting on a service), curls to internal hosts (warmups, notifications, registrations), file copies to odd paths (consumed elsewhere), env exports with no in-repo readers.
- If after investigating you still cannot explain a step, leave it alone and report it: name the step, what you checked, and what you'd need to know. Let the user decide.
- If removal is genuinely justified, make it its own commit with the evidence in the message — never folded into an unrelated change.
- Reordering counts. Steps may depend on side effects of earlier steps even without declared dependencies.

**Red flags that you're about to violate this:**

- "Nothing in the repo references this, so it's dead."
- "This sleep is obviously a hack someone forgot to remove."
- "The workflow will be cleaner without these legacy steps."
- "It still passes locally without this step, so it's safe to drop."
- "Whoever needs this would have documented it."
