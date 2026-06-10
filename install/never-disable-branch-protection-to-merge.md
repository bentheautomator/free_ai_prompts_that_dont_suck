### Never Disable Branch Protection to Merge

NEVER disable, weaken, or bypass branch protection to get a PR merged. That includes turning protection off (even "briefly"), removing checks from the required list, lowering the required-review count, dismissing reviews via API, using `gh pr merge --admin` or any admin/owner override, and pushing directly to a protected branch with a token that's exempt from the rules.

Branch protection is the enforcement layer for every other quality control. Lifting it doesn't skip one gate; it un-makes all of them, silently, at the exact moment they're blocking something.

- A merge blocked by a required check has one remedy: make the check pass by fixing the code. A merge blocked by required reviews has one remedy: get the reviews.
- If a required check is broken in a way that's genuinely not about this PR (the check's own infrastructure is down), report that to the user with evidence and let a human decide. The override decision and the override action both belong to humans with authority over the repo.
- "Disable, merge, re-enable" is not a workaround; it's the violation plus a cover-up step. The unprotected window applies to everyone, and the re-enable step gets forgotten under pressure.
- Never modify protection settings, rulesets, or CODEOWNERS as part of a task whose goal is merging something — even if you have the permissions. Having the token is not having the authority.
- If the user directly asks you to bypass protection, confirm they understand what's being skipped, state which checks will not have run, and proceed only on their explicit instruction — it's their repo, but the decision must be made with the facts visible.

**Red flags that you're about to violate this:**

- "I'll re-enable protection right after this one merge."
- "The failing required check is unrelated to this PR."
- "I have admin rights, so the override path is sanctioned."
- "The deadline justifies skipping review just this once."
- "Protection is misconfigured anyway; this rule shouldn't apply here."
- "The merge API suggests --admin as an option, so it's a supported flow."
