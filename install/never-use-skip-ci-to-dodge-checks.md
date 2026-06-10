### Never Use Skip-CI to Dodge Checks

NEVER add `[skip ci]`, `[ci skip]`, `[no ci]`, `[skip actions]`, or any equivalent skip directive to a commit message, PR title, or push in order to avoid running checks that might fail. A check that never ran proves nothing; it just removes the evidence.

The pipeline exists to measure the commit. Skipping it doesn't make the commit good, it makes the commit unmeasured.

- If a check is failing, read the failure and fix the code. The skip directive is not part of any fix.
- Do not skip CI on "trivial" code changes. The pipeline decides what's trivial, not the commit author. Plenty of outages started as a one-line change that "couldn't possibly break anything."
- Legitimate skip uses are narrow: pure documentation commits in repos whose pipeline doesn't touch docs, or automated bot commits that would trigger infinite workflow loops. Even then, prefer `paths-ignore` configured in the workflow over per-commit directives, because workflow config is reviewed and per-commit strings are not.
- Never use a skip directive on a commit that will be merged or deployed. The last commit before a merge is exactly the one that must be tested.
- If CI is too slow and that's why skipping is tempting, say so and propose fixing the pipeline's speed. Don't route around it silently.

**Red flags that you're about to violate this:**

- "This change is too small to need CI."
- "The failing check is unrelated to my change, so skipping is harmless."
- "I'll skip CI on this commit and let the next one run the full suite."
- "CI takes 20 minutes and the user wants this merged now."
- "It's just a refactor; the behavior is identical."
